import json
import pymongo
import re
import time
import sys

from flask import Flask
from flask import request

app = Flask(__name__)

client = pymongo.MongoClient("mongodb://localhost/")
db = client["boavizta_energizta"]
states_collection = db["states"]
hosts_collection = db["hosts"]
# token_collection = db['tokens']

ENERGIZTA_VERSION = "0.1a"

# TODO
# - Retrieve states (token needed)
# - Retrieve hosts (token needed)
# - Display stats (number of hosts, number of states) (token needed)


@app.route("/pub/states", methods=["POST", "PUT"])
def insert_states():
    states = list()
    host = ""
    for line in request.data.splitlines():
        state = json.loads(line)

        if not all(
            k in state
            for k in (
                "host",
                "duration_us",
                "nb_states",
                "load1",
                "powers",
                "energizta_version",
            )
        ):
            return ("Error: Post data does not match expected format\n", 403)

        if state["energizta_version"] != ENERGIZTA_VERSION:
            return (
                "Error: Please run the test with the last version of energizta.sh (%s)\n"
                % ENERGIZTA_VERSION,
                403,
            )

        if not state["powers"]:
            return (
                "Error: At least one line does not have any power value, not interested\n",
                403,
            )

        if not host:
            host = state["host"]
            if hosts_collection.find_one({"id": host}) is None:
                return ("Error: Host %s is not in database.\n" % host, 404)
        else:
            if host != state["host"]:
                return ("Error: All lines must be for the same host.\n", 403)

        # print(state, file=sys.stderr)
        state["upload_timestamp"] = int(time.time())
        states.append(state)

    states_collection.insert_many(states)

    return ("% states received. Thank you!\n" % len(states), 204)


@app.route("/pub/test_host/<host_id>")
def test_host(host_id):
    if hosts_collection.find_one({"id": host_id}):
        return ("OK", 200)
    else:
        return ("NOK", 200)


@app.route("/pub/host", methods=["POST"])
def insert_host():
    req_data = request.get_json()

    try:
        machine_id, hardware_id, software_id = req_data["id"].split("_")
        if not re.findall(r"^([a-fA-F\d-]+)$", machine_id):
            raise Exception("%s is not a valid machine_id" % machine_id)
        if not re.findall(r"^([a-fA-F\d]{32})$", hardware_id):
            raise Exception("%s is not a valid hardware_id" % hardware_id)
        if not re.findall(r"^([a-fA-F\d]{32})$", software_id):
            raise Exception("%s is not a valid software_id" % software_id)
    except Exception as e:
        return ("Error: Host id is not properly formatted : %s\n" % e, 403)

    if hosts_collection.find_one({"id": req_data["id"]}):
        return ("Error: %s is already in database\n" % (req_data["id"]), 409)

    hosts_collection.insert_one(req_data)
    return ("", 204)


app.run(port=5001)
