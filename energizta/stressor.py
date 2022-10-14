#!/usr/bin/python3

from multiprocessing import cpu_count
from subprocess import PIPE, Popen
from time import ctime, sleep


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
    pass


class CPUStressor(Stressor):
    def __init__(self):
        super().__init__()
        self._cpu_num = cpu_count()

    @property
    def num_cpu(self):
        return self._cpu_num

    def start(self, load_percent):
        prog = '/usr/bin/stress-ng'
        cmdline = f'--cpu {self.num_cpu} -l {load_percent}'

        if not self.num_cpu:
            raise StressorException('Could not run stressor on 0 CPU!')

        self._process = Popen([prog] + cmdline.split(), stdout=PIPE)


def get_measure():
    return ctime()


def send_results(measures):
    print(measures)


def main():
    measures = []

    stress = CPUStressor()

    measures.append(get_measure())
    for i in range(0, 50, 10):
        stress.start(i)
        sleep(5)
        measures.append(get_measure())
        stress.stop()

    send_results(measures)


if __name__ == "__main__":
    main()
