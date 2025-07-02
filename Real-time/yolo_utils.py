# yolo_utils.py
import torch
import cv2
import cv2.img_hash
from collections import OrderedDict
from ultralytics import YOLO
from datetime import datetime

class YOLODetector:
    CLASSES = ['Eating', 'Working', 'Sleeping', 'Speaking on phone' , 'Working']

    def __init__(self, weights_path: str, device: str = None, max_cache_size: int = 30):
        self.device = device or ('cuda' if torch.cuda.is_available() else 'cpu')
        self.model = YOLO(weights_path).to(self.device)
        self.hash_func = cv2.img_hash.PHash_create()
        self.cache = OrderedDict()
        self.max_cache = max_cache_size

    def predict(self, frame):
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        key = tuple(self.hash_func.compute(gray).flatten())
        if key in self.cache:
            results = self.cache[key]
            self.cache.move_to_end(key)
        else:
            with torch.no_grad():
                results = self.model(frame, device=self.device)[0]
            self.cache[key] = results
            if len(self.cache) > self.max_cache:
                self.cache.popitem(last=False)
        return results

class DeskActivityMonitor:
    def __init__(self, detector: YOLODetector, office_areas: dict, fb_client, excel_logger):
        self.detector = detector
        self.office_areas = office_areas
        self.fb = fb_client
        self.excel = excel_logger
        C = YOLODetector.CLASSES
        self.timers     = {d: {c: 0 for c in C} for d in office_areas}
        self.entry_times= {d: {} for d in office_areas}
        self.prev_active= {d: {c: False for c in C} for d in office_areas}

    def process_frame(self, frame):
        small = cv2.resize(frame, (640, 360))
        now_ts = datetime.now().timestamp()
        now_str = datetime.now().strftime('%Y-%m-%d')
        results = self.detector.predict(small)

        current = {d: {c: False for c in self.detector.CLASSES} for d in self.office_areas}
        for box in results.boxes:
            if box.conf[0] < 0.5:
                continue
            x1,y1,x2,y2 = map(int, box.xyxy[0].tolist())
            cls = self.detector.CLASSES[int(box.cls[0])]
            cx, cy = (x1+x2)//2, (y1+y2)//2
            for d,(dx1,dy1,dx2,dy2) in self.office_areas.items():
                if dx1<=cx<=dx2 and dy1<=cy<=dy2:
                    current[d][cls] = True
                    last = self.entry_times[d].get(cls, now_ts)
                    self.timers[d][cls] += now_ts - last
                    self.entry_times[d][cls] = now_ts

        for d in self.office_areas:
            for c,active in current[d].items():
                if active and not self.prev_active[d][c]:
                    ts = datetime.now().strftime('%H:%M:%S')
                    self.fb.push(f'desk_activity_logs/{d}/{c}/{now_str}', {'start': ts})

        annotated = results.plot()
        for d,(dx1,dy1,dx2,dy2) in self.office_areas.items():
            color = (0,255,0) if current[d]['Working'] else (0,0,255)
            cv2.rectangle(annotated,(dx1,dy1),(dx2,dy2),color,2)
            y = dy2 + 20
            row = [d]
            payload = {}
            for c in self.detector.CLASSES:
                sec = int(self.timers[d][c])
                row.append(sec if sec>0 else '')
                if sec>0:
                    payload[c] = sec
                cv2.putText(annotated, f"{d}-{c}: {sec}s", (dx1,y),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,255),1)
                y += 15
            if payload:
                self.fb.update(f'desk_times/{d}', payload)
                self.fb.update(f'desk_times_history/{now_str}/{d}', payload)
                self.excel.append_row(row)

        self.prev_active = {d: current[d].copy() for d in self.office_areas}
        return annotated