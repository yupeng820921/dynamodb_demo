#! /usr/bin/env python

import os
import time
import json
import yaml
import signal
from flask import Flask, request, redirect, url_for, render_template, abort, Response

with open(u'%s/client_conf.yaml' % os.path.split(os.path.realpath(__file__))[0], u'r') as f:
    conf = yaml.safe_load(f)

pid_file = conf[u'pid_file']
task_file = conf[u'task_file']
result_file = conf[u'result_file']
raw_result_file = conf[u'raw_result_file']

app = Flask(__name__)

def make_resp(data, status):
    js = json.dumps(data)
    resp = Response(js, status=status, mimetype='application/json')
    return resp

@app.route(u'/', methods=[u'GET', u'POST'])
def index():
    if request.method == u'POST':
        try:
            data = request.json
        except Exception, e:
            ret_data = {u'reason': u'not json format'}
            return make_resp(ret_data, 400)
        print(data)
        # data = json.loads(data)
        if u'action' not in data:
            ret_data = {u'reason': u'no action'}
            return make_resp(ret_data, 400)
        try:
            with open(pid_file, u'r') as f:
                task_pid = int(f.read().strip())
        except Exception, e:
            ret_data = {u'reason': u'pid_file %s' % e}
            return make_resp(ret_data, 400)
        action = data[u'action']
        if action == u'stop':
            os.kill(task_pid, signal.SIGUSR2)
            ret_data = {u'reason': u'success'}
            return make_resp(ret_data, 202)
        if os.path.exists(task_file):
            ret_data = {u'reason': u'a task is running'}
            return make_resp(ret_data, 400)
        try:
            with open(task_file, u'w') as f:
                data = json.dumps(data)
                f.write(data)
        except Exception, e:
            ret_data = {u'reason': unicode(e)}
            return make_resp(ret_data, 400)
        os.kill(task_pid, signal.SIGUSR1)
        ret_data = {u'reason': u'success'}
        return make_resp(ret_data, 202)
    if os.path.exists(task_file):
        try:
            with open(task_file, u'r') as f:
                task_detail = f.read()
        except Exception, e:
            return e;
        return task_detail
    else:
        return u'idle'

@app.route(u'/result', methods=[u'GET'])
def result():
    retry_count = 10
    while retry_count > 0:
        try:
            with open(result_file, u'r') as f:
                result = f.read()
        except Exception, e:
            result = u'no data'
            break
        if result:
            break
        time.sleep(0.01)
    return result

@app.route(u'/raw_result', methods=[u'GET'])
def raw_result():
    try:
        with open(raw_result_file, u'r') as f:
            raw_result = f.read()
    except Exception, e:
        raw_result = u'no result'
    return render_template(u'raw_result.html', raw_result=raw_result)

if __name__ == u'__main__':
    app.debug = True
    app.run(host=u'0.0.0.0', port=80)
