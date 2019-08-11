#!/usr/bin/python3

import os
import sys
import time
import subprocess
from threading import Timer
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, RegexMatchingEventHandler


def debounce(wait):
    """ Decorator that will postpone a functions
        execution until after wait seconds
        have elapsed since the last time it was invoked. """
    def decorator(fn):
        def debounced(*args, **kwargs):
            def call_it():
                fn(*args, **kwargs)
            try:
                debounced.t.cancel()
            except(AttributeError):
                pass
            debounced.t = Timer(wait, call_it)
            debounced.t.start()
        return debounced
    return decorator


class CertFilesHandler(FileSystemEventHandler):
    def __init__(self, observer):
        self.observer = observer

    def watch(self, file_path):
        print("[INFO] Watching %s" % file_path)
        self.observer.schedule(self, file_path)

    def on_any_event(self, event):
        if event.is_directory:
            return
        print("[INFO] Watched Event %s" % repr(event))
        self.reload_certificates()

    @debounce(3)
    def reload_certificates(self):
        status = subprocess.call(['certs_helper.sh', 'reload'])
        if status != 0:
            print("[INFO] Failed to reload certs")


if __name__ == "__main__":
    observer = Observer()
    handler = CertFilesHandler(observer)
    for path in sys.argv[1:]:
        if not os.path.exists(path):
            print("[INFO] Skip watching %s - it does not exist" % path)
            continue
        handler.watch(path)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
