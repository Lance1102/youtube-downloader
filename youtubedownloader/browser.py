﻿# This Python file uses the following encoding: utf-8
from PySide2.QtCore import QObject, QFileSystemWatcher, Qt, Signal, Slot, Property

from .logger import create_logger

import os, os.path, json, lz4.block, subprocess

class Firefox(QObject):
    TABS_LOCATION_COMMAND = ["find ~/.mozilla/firefox*/*.default/sessionstore-backups/recovery.jsonlz4"]
    MOZILLA_MAGIC_NUMBER = 8 # NOTE: https://gist.github.com/mnordhoff/25e42a0d29e5c12785d0

    tabs_changed = Signal("QVariantList")

    def __init__(self):
        super(Firefox, self).__init__(None)

        self.logger = create_logger(__name__)
        self._tabs = []

        try:
            self._tabs_location = subprocess.check_output(Firefox.TABS_LOCATION_COMMAND, shell=True).decode("utf-8").replace("\n", "")
            self.logger.info("Firefox detected={tabs_location}".format(tabs_location=(bool(self._tabs_location != ""))))

            self._firefox_tabs_file_watcher = QFileSystemWatcher()
            self.get_firefox_tabs(self._tabs_location)
            self._firefox_tabs_file_watcher.fileChanged.connect(self.get_firefox_tabs, Qt.QueuedConnection)

            self._running = True

        except subprocess.CalledProcessError as error:
            self._running = False

    @Property(bool, constant=True)
    def running(self):
        return self._running

    @Slot(str)
    def get_firefox_tabs(self, path):
        self._tabs = []

        if not path in (self._firefox_tabs_file_watcher.files()):
            self._firefox_tabs_file_watcher.addPath(self._tabs_location)

        tabs_file = open(self._tabs_location, "rb")
        mozilla_magic = tabs_file.read(Firefox.MOZILLA_MAGIC_NUMBER)
        j_data = json.loads(lz4.block.decompress(tabs_file.read()).decode("utf-8"))
        tabs_file.close()

        for window in j_data.get("windows"):
            for tab in window.get("tabs"):
                index = int(tab.get("index")) - 1
                self._tabs.append({
                        "url": tab.get("entries")[index].get("url"),
                        "title": tab.get("entries")[index].get("title")
                    })

        self.tabs_changed.emit(self._tabs)

    def read_tabs(self):
        return self._tabs

    def set_tabs(self, new_tabs):
        self._tabs = new_tabs
        self.tabs_changed.emit()

    tabs = Property("QVariantList", read_tabs, set_tabs, notify=tabs_changed)
