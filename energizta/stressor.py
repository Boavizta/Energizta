#!/usr/bin/python3

from multiprocessing import cpu_count
from subprocess import Popen
from time import ctime, sleep, time
from json import dump


class StressorException(Exception):
    pass


class Stressor:
    def __init__(self):
        self._path = '/usr/bin/stress-ng'
        self._cmdline = ''
        self._process = None

    def start(self):
        self._process = Popen([self._path] + self._cmdline.split())

    def stop(self):
        if not self._process:
            raise StressorException('No process started!')

        self._process.kill()

    def run_for(self, sleep_until):
        self.start()
        sleep(sleep_until)
        self.stop()


class RAMStressor(Stressor):
    def __init__(self, workers=2):
        super().__init__()
        self._workers_num = workers
        self._cmdline = f'--vm {self.workers} --vm-bytes 1G'

    @property
    def workers(self):
        return self._workers_num

    @property
    def name(self):
        return 'stress-ng ram'


class CPUStressor(Stressor):
    def __init__(self):
        super().__init__()
        self._start = 0
        self._load = 100
        self._cpu_num = cpu_count()
        self._cmdline = f'--cpu {self.num_cpu} -l {self.load}'

        if not self.num_cpu:
            raise StressorException('Could not run stressor on 0 CPU!')

    @property
    def num_cpu(self):
        return self._cpu_num

    @property
    def name(self):
        return 'stress-ng cpu'

    @property
    def load(self):
        return self._load

    @load.setter
    def load(self, load):
        if 0 < load <= 100:
            self._load = load
            self._cmdline = f'--cpu {self.num_cpu} -l {self.load}'
        else:
            raise StressorException('Invalid load specified')


def get_measure():
    return ctime()


def send_results(stress_name, measures):
    print(measures)
    querry = {}

    hardware = {}
    hardware["cpus"] = [
                            {
                                "name": "Intel(R) Core(TM) i7-7700HQ CPU",
                                "core_units": 8
                            }
                        ]
    hardware["rams"] = [
                            {
                                "vendor": None,
                                "capacity": 16
                            }
                        ]
    hardware["disks"] = [
                                {
                                    "capacity": 931,
                                    "vendor": "HGST",
                                    "type": "hdd"
                                },
                                {
                                    "capacity": 238,
                                    "vendor": "Micron_1100_MTFD",
                                    "type": "ssd"
                                }
                        ]

    querry["device_id"] = None
    querry["contributor"] = None
    querry["hardware"] = hardware

    states = []
    for measure in measures:
        state = {
                    "type": stress_name,
                    "powers": [
                        {
                            "source": "should not be trusted",
                            "scope": "cpu",
                            "value": measure
                        }
                    ],
                    "temperature": None,
                    "disks_io": None,
                    "ram_io": None,
                    "cpu_percent_user": None,
                    "cpu_percent_sys": None,
                    "cpu_percent_iowait": None,
                    "netstats": None
                }
        states.append(state)
    querry["states"] = states
    querry["date"] = int(time())
    with open("toto", "w") as fs:
        dump(querry, fs)


def main():
    measures = []

    # Get initial power measure
    measures.append(get_measure())

    # Run CPU Stressor for 15 seconds
    # By default, it runs at 100% of CPU load
    stress = CPUStressor()
    stress.run_for(15)

    # Get current power measure
    measures.append(get_measure())

    # Now run a progressive CPU stressor
    # from 10% to 50% of load
    # Save power measure at each step
    for load in range(10, 50, 10):
        stress.load = load
        stress.run_for(10)
        measures.append(get_measure())

    send_results(stress.name, measures)


if __name__ == "__main__":
    main()
