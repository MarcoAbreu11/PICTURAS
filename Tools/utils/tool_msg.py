import json

from .rabbit_mq import Rabbit_MQ

"""
# Callback example for those who need it
def callback(ch, method, properties, body):
    print(f" [x] Received {body.decode()}")
"""

class ToolMSG:
    queues = {
        'border': 'border_queue',
        'brightness': 'brightness_queue',
        'contrast': 'contrast_queue',
        'cut': 'cut_queue',
        'scale': 'scale_queue',
        'saturation': 'saturation_queue',
        'binarization': 'binarization_queue',
        'rotate': 'rotate_queue',
        'resize': 'resize_queue',
        'cut_ai': 'cut_ai_queue',
        'upgrade_ai': 'upgrade_ai_queue',
        'bg_remove_ai': 'bg_remove_ai_queue',
        'text_ai': 'text_ai_queue',
        'obj_ai': 'obj_ai_queue',
        'people_ai': 'people_ai_queue',
        'expand_ai': 'expand_ai_queue',
        'extract_frames': 'extract_frames_queue',
        'trim': 'trim_queue',
        'project': 'project_queue'
    }

    output_types = ("image", "text", "images", "video")
    
    def __init__(self, microservice_name, tool_name, rabbit_host, rabbit_port, username, password):
        self._microservice_name = microservice_name
        self._queue = self.queues[tool_name]
        self._proj_queue = self.queues['project']
        self._rabbit_mq = Rabbit_MQ(rabbit_host, rabbit_port, username, password)
    
    def read_msg(self, callback):
        self._rabbit_mq.read_rabbit_msg(self._queue, callback)

    def send_msg(self, msg_id, resp_msg_id, timestamp, status, processingTime, new_img_uri, type="image", err_code=None, err_msg=None, og_img_uri=None, images=None):

        msg = {}

        # Várias tools chamam o erro sem o argumento `type`, o que desloca os restantes
        # (o código de erro cai em `type`). Realinha-os para o erro chegar ao projects.
        if status == "error" and og_img_uri is None and type not in self.output_types:
            type, err_code, err_msg, og_img_uri = "image", type, err_code, err_msg

        match status:
            case "success":
                msg = {
                    "messageId": resp_msg_id,
                    "correlationId": msg_id,
                    "timestamp": timestamp,
                    "status": status,
                    "output": {
                        "type": type,
                        "imageURI": new_img_uri
                    },
                    "metadata": {
                        "processingTime": processingTime,
                        "microservice": self._microservice_name
                    }
                }
                # type "images": lista de { imageURI, time } (ex.: extract_frames)
                if images is not None:
                    msg["output"]["images"] = images
            case "error":
                if err_code is None or err_msg is None or og_img_uri is None:
                    raise Exception("Make sure, in case of error status, err_code, err_msg and og_img_uri are not None")

                # o projects procura o process pelo correlationId (= id do pedido)
                msg = {
                    "messageId": resp_msg_id,
                    "correlationId": msg_id,
                    "timestamp": timestamp,
                    "status": status,
                    "error": {
                        "code": err_code,
                        "message": err_msg,
                        "details": {
                            "inputFileURI": og_img_uri
                        }
                    },
                    "metadata": {
                        "processingTime": processingTime,
                        "microservice": self._microservice_name
                    }
                }
            case _:
                msg = {}
                
        msg = json.dumps(msg)

        self._rabbit_mq.send_rabbit_msg(msg, self._proj_queue)

    def keep_alive(self):
        self._rabbit_mq.keep_alive()

    # Progresso intermédio (0-100) de um pedido ainda em curso
    def send_progress(self, msg_id, resp_msg_id, timestamp, progress):
        msg = {
            "messageId": resp_msg_id,
            "correlationId": msg_id,
            "timestamp": timestamp,
            "status": "progress",
            "output": {"progress": progress},
        }
        self._rabbit_mq.send_rabbit_msg(json.dumps(msg), self._proj_queue)
        
    