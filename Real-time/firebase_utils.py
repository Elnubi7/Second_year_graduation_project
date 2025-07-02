# firebase_utils.py
from firebase_admin import credentials, db, initialize_app
from threading import Thread
from queue import Queue

class FirebaseClient:
    def __init__(self, service_account_path: str, database_url: str):
        cred = credentials.Certificate(service_account_path)
        initialize_app(cred, {'databaseURL': database_url})
        self.queue = Queue()
        self._start_worker()

    def _start_worker(self):
        t = Thread(target=self._worker, daemon=True)
        t.start()

    def _worker(self):
        while True:
            item = self.queue.get()
            try:
                path, payload, mode = item
                ref = db.reference(path)
                if mode == 'push':
                    ref.push(payload)
                else:
                    ref.update(payload)
            finally:
                self.queue.task_done()

    def update(self, path: str, payload: dict):
        self.queue.put((path, payload, 'update'))

    def push(self, path: str, payload: dict):
        self.queue.put((path, payload, 'push'))