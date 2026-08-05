import sys
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import QUrl
from PySide6.QtWebEngineWidgets import QWebEngineView

URL='https://grayhaired.tech/desktop-c/'

app=QApplication(sys.argv)
view=QWebEngineView()
view.setWindowTitle('GrayHaired Desktop')
view.resize(1400,900)
view.load(QUrl(URL))
view.show()
sys.exit(app.exec())
