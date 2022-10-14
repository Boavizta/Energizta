#!/usr/bin/python3

from multiprocessing import cpu_count
from subprocess import PIPE, Popen
from time import ctime, sleep


def start_stress(num_cpu, load_percent):
    prog = '/usr/bin/stress-ng'
    cmdline = f'--cpu {num_cpu} -l {load_percent}'

    print(f'Executing {prog} {cmdline}')
    p = Popen([prog] + cmdline.split(), stdout=PIPE)
    return p


def stop_stress(process):
    print(f'Killing process {process}')
    process.kill()
    print('Process killed!')


def get_cpu_count():
    return cpu_count()


def get_measure():
    return ctime()


def send_results(measures):
    print(measures)


def main():
    measures = []
    num_cpu = get_cpu_count()
    print(f'Got {num_cpu} CPU(s)')

    measures.append(get_measure())
    for i in range(0, 50, 10):
        process = start_stress(num_cpu, i)
        sleep(5)
        measures.append(get_measure())
        stop_stress(process)

    send_results(measures)


if __name__ == "__main__":
    main()
