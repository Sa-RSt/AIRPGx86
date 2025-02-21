import sys
import json
import struct
from urllib.request import Request, urlopen
import time


HALT = 0xFFFFFFFFFFFFFFFF


def read_null_terminated_string():
    out = bytearray()
    byte = sys.stdin.buffer.read(1)
    while byte != b'\0':
        out.extend(byte)
        byte = sys.stdin.buffer.read(1)
    return out.decode(errors='ignore')


def write_null_terminated_string(s):
    sys.stdout.buffer.write(s.encode())
    sys.stdout.buffer.write(b'\0')
    sys.stdout.buffer.flush()


def read_context():
    number_of_elements = struct.unpack('@N', sys.stdin.buffer.read(8))[0]
    if number_of_elements == HALT:
        return None
    context = []
    for _ in range(number_of_elements):
        context.append({'role': read_null_terminated_string(), 'content': read_null_terminated_string()})
    return context


def write_reply(message):
    write_null_terminated_string(message['role'])
    write_null_terminated_string(message['content'])


def write_status_ready():
    sys.stdout.buffer.write(b'U' * 8)
    sys.stdout.buffer.flush()


def write_status_error():
    sys.stdout.buffer.write(b'\xff' * 8)
    sys.stdout.buffer.flush()


def make_api_request(context, api_key):
    body = {
        'model': 'gpt-4o',
        'temperature': .6,
        'messages': context,
    }
    ser = json.dumps(body).encode()
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer {}'.format(api_key)
    }
    req = Request('https://api.openai.com/v1/chat/completions', data=ser, method='POST', headers=headers)
    wait = 0.5
    for _ in range(5):
        try:
            with urlopen(req) as resp:
                if resp.code == 200:
                    return json.load(resp)['choices'][0]['message']
                else:
                    wait *= 2
        except OSError:
            wait *= 2
        time.sleep(wait)
    return None


def main():
    api_key = read_null_terminated_string()
    write_status_ready()
    while 1:
        ctx = read_context()
        if ctx is None:
            break
        resp = make_api_request(ctx, api_key)
        if resp:
            write_reply(resp)
        else:
            write_status_error()

main()
