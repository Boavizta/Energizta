#!/usr/bin/python3

from multiprocessing import cpu_count
from subprocess import PIPE, Popen
from time import ctime, sleep, time
from json import dump


class StressorException(Exception):
    pass


class Stressor:
    def __init__(self):
        self._process = None

    def start(self):
        raise NotImplementedError()

    def stop(self):
        if not self._process:
            raise StressorException('No process started!')

        self._process.kill()


class RAMStressor(Stressor):
    def __init__(self, workers=2):
        super().__init__()
        self._workers_num = workers

    @property
    def workers(self):
        return self._workers_num

    @property
    def name(self):
        return 'stress-ng ram'

    def start(self):
        prog = '/usr/bin/stress-ng'
        cmdline = f'--vm {self.workers} --vm-bytes 1G'

        self._process = Popen([prog] + cmdline.split(), stdout=PIPE)


class CPUStressor(Stressor):
    def __init__(self):
        super().__init__()
        self._cpu_num = cpu_count()

    @property
    def num_cpu(self):
        return self._cpu_num

    @property
    def name(self):
        return 'stress-ng cpu'

    def start(self, load_percent):
        prog = '/usr/bin/stress-ng'
        cmdline = f'--cpu {self.num_cpu} -l {load_percent}'

        if not self.num_cpu:
            raise StressorException('Could not run stressor on 0 CPU!')

        self._process = Popen([prog] + cmdline.split(), stdout=PIPE)


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

    stress = CPUStressor()

    measures.append(get_measure())
    for i in range(0, 50, 10):
        stress.start(i)
        sleep(5)
        measures.append(get_measure())
        stress.stop()

    send_results(stress.name, measures)


if __name__ == "__main__":
    main()
