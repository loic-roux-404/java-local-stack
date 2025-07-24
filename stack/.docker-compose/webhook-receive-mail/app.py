import http.client
from flask import Flask, request
import subprocess
import json
import logging
import os
import sys

app = Flask(__name__)
logging.basicConfig(
    level=int(os.environ.get('LOG_LEVEL', logging.INFO)),
    stream=sys.stdout)


HOST = os.environ.get("MAIL_WEBHOOK_HOST", "host.docker.internal")

def is_port_open(port):
    try:
        conn = http.client.HTTPConnection(HOST, port, timeout=1)
        conn.connect()
        conn.close()
        return True
    except Exception as e:
        logging.debug(f"Port {port} not open: {e}")
        return False

def send_request(port, endpoint, ruleset, raw_email, headers):
    conn = http.client.HTTPConnection(HOST, port)
    url = f"{endpoint}?dry=false&ruleSet={ruleset}"
    conn.request("POST", url, raw_email, headers)
    res = conn.getresponse()
    content = res.read().decode("utf8")

    logging.info(f"{url} - {res.status} - {content}")

    return content

def send_if_port_open(port, endpoint, ruleset, raw_email, headers):
    if is_port_open(port):
        return send_request(port, endpoint, ruleset, raw_email, headers)

    return ""


def insertBefore(haystack, needle, newText):
    #""" Inserts 'newText' into 'haystack' right after 'needle'. """
    i = haystack.find(needle)
    return haystack[:i] + newText[1:] + haystack[i:]


@app.route('/receive-mail', methods=['POST'])
def run_script():
    message_id = json.loads(request.data.decode('utf-8'))['ID']

    logging.info(f"Mailpit message : {message_id}")

    mailpit_conn = http.client.HTTPConnection("mailpit", 8025)
    mailpit_conn.request("GET", f"/api/v1/message/{message_id}/raw")
    raw_email_res = mailpit_conn.getresponse()
    additional_headers = os.environ.get("MAIL_WEBHOOK_ADDITIONAL_HEADERS", "")

    raw_email = raw_email_res.read().decode("utf8")

    raw_email = raw_email.replace("Message-Id", "Message-ID")

    raw_email = insertBefore(raw_email, "From", additional_headers)

    logging.info(raw_email)

    headers = {
      'Content-Type': 'message/rfc822',
      'Accept': '*/*',
      'X-PLATEFORM-USER': os.environ.get("MAIL_WEBHOOK_USER_ID", "adminAwl"),
    }

    logging.debug(headers)

    return '\n'.join(map(lambda request_dict: send_if_port_open(**request_dict), [
      {
        'port': os.environ.get('MAIL_WEBHOOK_ROUTING_PORT', 8001),
        'endpoint': os.environ.get('MAIL_WEBHOOK_ROUTING_ENDPOINT', "/routing/mail"),
        'raw_email': raw_email,
        'headers': headers
      }
    ]))

if __name__ == "__main__":
    app.run(host='0.0.0.0')
