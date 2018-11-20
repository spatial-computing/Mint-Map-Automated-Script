#### message_queue.py

from services.client import Consumer
#import Consumer
from services.consume_func import *
import requests


def test_request_dcat_once():
   consumer = Consumer("localhost", "5000", "dataset")
   resp = consumer.consume(0, 20)
   print(resp)


def test_request_dcat_continuous():

   def print_message(resp):
       print("message", resp["messages"])
       print("new offset", resp["offset"])

   #consumer = Consumer(“localhost”, “5000”)
   consumer = Consumer("localhost", "5000", "test")
   consumer.continuous_consume(consume_func, offset=0, limit=1, sleeping_time=5)