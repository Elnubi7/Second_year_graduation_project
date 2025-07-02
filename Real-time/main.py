import cv2
import time
from datetime import datetime
from excel_utils import ExcelLogger
from firebase_utils import FirebaseClient
from yolo_utils import YOLODetector, DeskActivityMonitor

EXCEL_PATH       = "desk_times_history.xlsx"
SERVICE_ACCOUNT  = "service_account.json"
DATABASE_URL     = "https://employeeapp-6a763-default-rtdb.firebaseio.com/"
WEIGHTS_PATH     = "C:/active reco/runs/detect/train18/weights/best.pt"

OFFICE_AREAS = {
    "Desk1": (100, 100, 300, 300),
    "Desk2": (400, 100, 600, 300)
}

excel_logger = ExcelLogger(EXCEL_PATH)
fb_client    = FirebaseClient(SERVICE_ACCOUNT, DATABASE_URL)

detector    = YOLODetector(WEIGHTS_PATH, max_cache_size=30)
monitor     = DeskActivityMonitor(detector, OFFICE_AREAS, fb_client, excel_logger)
cap = cv2.VideoCapture(0)
if not cap.isOpened():
    raise RuntimeError("Cannot open camera")

last_reset = time.time()
last_save  = time.time()

while True:
    ret, frame = cap.read()
    if not ret:
        break

    if int(time.time() * 10) % 2 == 0:
        continue

    if time.time() - last_reset >= 86400:
        for d in monitor.timers:
            for c in monitor.timers[d]:
                monitor.timers[d][c] = 0
        last_reset = time.time()

    annotated = monitor.process_frame(frame)
    cv2.imshow("Desk Monitoring", annotated)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

    if time.time() - last_save >= 60:
        excel_logger.save()
        last_save = time.time()
excel_logger.finalize()
excel_logger.save()
cap.release()
cv2.destroyAllWindows()