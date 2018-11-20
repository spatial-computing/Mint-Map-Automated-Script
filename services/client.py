#### client.py

class Consumer:

    def __init__(self, servers_host, servers_port, topic_name):
       self.servers_host = servers_host
       self.servers_port = servers_port
       self.topic = topic_name

    #def consume(self, offset: int, limit: int) -> dict:     #def consume(self, offset, limit):
    def consume(self, offset, limit):
        resp = requests.get(f"http://{self.servers_host}:{self.servers_port}/mq/{self.topic}",
        params={"offset": offset, "limit": limit})
        return resp.json()


    #def continuous_consume(self, func: Callable, offset: int=0, limit: int=20, sleeping_time: int=300):
    def continuous_consume(self, func, offset=0, limit=20, sleeping_time=300):
        while True:
            resp = self.consume(offset, limit)
            # get and update to the new offset
            offset = resp['offset']
            func(resp, out_dir)

            if len(resp['messages']) == 0:
                print("Receiving no data, sleeping time for 5 minutes...")
                time.sleep(sleeping_time)