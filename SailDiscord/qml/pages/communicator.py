# This Python file uses the following encoding: utf-8

# if __name__ == "__main__":
#     pass
import pyotherside
from threading import Thread

if __name__ == "__main__":
    # print("Python is UP!") # Print statements do not work here
    pyotherside.send("UP")   # Debug this way instead (also add some code in QML)
