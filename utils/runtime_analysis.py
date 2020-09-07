"""
Run time analysis for each geographic location in the log files

Run from the command line, passing a single parameter of the path to the log file to analyse.
Note 23:59:59 denotes a no result location
"""
import argparse
import re
from datetime import datetime, timedelta
from typing import Dict, Union

TIMING_REGEX = re.compile(r"\[([\d\- :]*)\] (\w+) estimates for: (.+)")


class LocationRun:
    """small class that holds the start, end and runtime for any given location"""

    def __init__(self):
        """ set the default values """
        # init
        self.__start = None
        self.__end = None
        self.__runtime = timedelta(hours=23, minutes=59, seconds=59)

    @property
    def start(self) -> Union[datetime, None]:
        """
        start time
        :return: datetime
        """
        return self.__start

    @start.setter
    def start(self, value: datetime):
        """
        Set the start value
        :param value: datetime
        """
        self.__start = value
        self.runtime_check()

    @property
    def end(self) -> Union[datetime, None]:
        """
        end time
        :return: datetime
        """
        return self.__end

    @end.setter
    def end(self, value: datetime):
        """
        get end time
        :param value: datetime
        """
        self.__end = value
        self.runtime_check()

    @property
    def runtime(self) -> timedelta:
        """
        get the runtime
        :return: timedelta
        """
        return self.__runtime

    def runtime_check(self):
        """
        if start and end are present calculate the runtime
        """
        if self.__end and self.__start:
            self.__runtime = self.__end - self.__start


def process_arguments():
    """
    deal with all the argument parsing, etc
    :return: argparse parse_args object - containing .log_file with the filepath
    """
    parser = argparse.ArgumentParser("Covid RT Estimate runtime log parser")
    parser.add_argument("log_file", type=str, help="full path to log file")
    return parser.parse_args()


def load_data_from_log(log_file_path: str) -> Dict[str, LocationRun]:
    """
    unpack that log file
    :param log_file_path: string of filepath to the log file
    :return: geographic location and runtime dictionary
    """
    locations = {}
    for line in open(log_file_path):
        for match in TIMING_REGEX.findall(line):
            date = datetime.strptime(match[0], '%Y-%m-%d %H:%M:%S')
            if match[2] not in locations and match[1] in ("Initialising", "Completed"):
                locations.update({match[2]: LocationRun()})
            if match[1] == "Initialising":
                locations[match[2]].start = date
            elif match[1] == "Completed":
                locations[match[2]].end = date
    return locations


def present_data(data: Dict[str, LocationRun]):
    """
    sort and print in csv format to the screen
    :param data:
    """
    for key in sorted(data, key=lambda name: data[name].runtime):
        print(f"{key}, {data[key].runtime}")


def run():
    """
    main runtime
    """
    args = process_arguments()
    data = load_data_from_log(args.log_file)
    present_data(data)


if __name__ == '__main__':
    run()
