#! /usr/bin/env python

import os
import time
import yaml
import random
import ConfigParser
from flask import Flask, request, redirect, url_for, render_template, abort
import boto
import boto.dynamodb2
from boto.dynamodb2.table import Table

with open(u'%s/server_conf.yaml' % os.path.split(os.path.realpath(__file__))[0], u'r') as f:
    conf = yaml.safe_load(f)

region = conf[u'region']
table_name = conf[u'table_name']
conn = boto.dynamodb2.connect_to_region(region)
table = Table(table_name, connection=conn)

app = Flask(__name__)

@app.route(u'/')
def index():
    return u'demo'

@app.route(u'/download')
@app.route(u'/download/<name>')
def get_data(name=None):
    items = table.query(name__eq=name, reverse=False, limit=1)
    # items = [{u'date':'2014',u'score':'198'}]
    find = False
    for item in items:
        date = item[u'date']
        score = item[u'score']
        find = True
    if not find:
        abort(404)
    return u'%s %s %s\n' % (name, date, score)

date_string = u'20140418152736'
@app.route(u'/upload')
@app.route(u'/upload/<name>')
def up_date(name=None):
    score = request.args.get(u'score')
    try:
        score = int(score)
    except Exception, e:
        abort(400)
    if not score:
        abort(400)
    date = date_string
    table.put_item(data={u'name':name, u'date':date, u'score':score}, overwrite=True)
    return u'%s %s %s\n' % (name, date, score)

if __name__ == u'__main__':
    app.debug = True
    app.run(host=u'0.0.0.0', port=80)
