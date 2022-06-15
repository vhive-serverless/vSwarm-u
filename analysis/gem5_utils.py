#!/usr/bin/python
# -*- coding: UTF8 -*-
import csv
import json

import collections
from numpy import dtype
from objectpath import *
from os import path, listdir, stat
from pyparsing import Word, Optional, ParseException, printables, nums, restOfLine
import matplotlib.pyplot as plt
import pandas as pd
import pickle
import seaborn as sns


class ExperimentResults:
    def __init__(self, configs, stats, props):
        self.configs = configs
        self.stats = stats
        self.props = props


class ExperimentConfigs:
    def __init__(self, raw_configs):
        self.raw_configs = raw_configs

    def __getitem__(self, index):
        return self.raw_configs.execute('$.' + index)


class ExperimentStats:
    def __init__(self, raw_stats):
        self.raw_stats = raw_stats

    def __getitem__(self, index):
        return self.raw_stats[index] if index in self.raw_stats else None


def read_configs(result_dir, config_json_file_name):
    try:
        with open(path.join(result_dir, config_json_file_name)) as config_json_file:
            # configs = Tree(json.load(config_json_file))
            configs = json.load(config_json_file)
    except Exception as e:
        print(e)
        return None
    else:
        return configs


def read_stats(result_dir, stats_file_name):
    stat_rule = Word(printables) + Word('nan.%' + nums) + Optional(restOfLine)

    stats = []

    try:
        with open(path.join(result_dir, stats_file_name)) as stats_file:
            i = 0
            for stat_line in stats_file:
                if len(stats) <= i:
                    stats.append(collections.OrderedDict())

                try:
                    stat = stat_rule.parseString(stat_line)
                    key = stat[0]
                    value = stat[1]

                    stats[i][key] = value
                except ParseException as e:
                    # print(e)
                    pass

                if 'End Simulation Statistics' in stat_line:
                    i += 1
    except Exception as e:
        print(e)
        return None
    else:
        return stats

def find_stats(result_dir, stats_file_name="stats.txt"):
    ## In case this is the first time we read values from this directory
    #  Or if the stats file has changed in the meantime parse the file to be more faster
    filename = result_dir + "/" + stats_file_name[:-5]
    if not path.exists(filename) or path.getmtime(result_dir + "/" + stats_file_name) > path.getmtime(filename):
        tmp = read_stats(result_dir, stats_file_name)
        with open(filename, 'wb') as f:
            pickle.dump(tmp,f)

    with open(filename, 'rb') as f:
        stats = pickle.load(f)
        return stats
    return None


def find_stats_group(result_dir):
    ## With this function we want to get the values from an entire folder full of results
    subdirs = [s for s in listdir(result_dir) if path.isdir(result_dir + s)]
    subdirs.sort()
    stats_group = {}

    for subdir in subdirs:
        stats = find_stats(path.join(result_dir,subdir))
        if stats:
            stats_group[subdir] = stats

    return stats_group



def parse_result(result_dir, config_json_file_name='config.json', stats_file_name='stats.txt', **props):
    return ExperimentResults(ExperimentConfigs(read_configs(result_dir, config_json_file_name)),
                             [ExperimentStats(stat) for stat in read_stats(result_dir, stats_file_name)], props)


def to_csv(output_file_name, results, fields):
    with open(output_file_name, 'w') as output_file:
        writer = csv.writer(output_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)

        writer.writerow([field[0] for field in fields])

        for result in results:
            writer.writerow([field[1](result) for field in fields])

def to_pandas(results, fields):
    columns = [field[0] for field in fields]
    dtype = {s:t for s,t in zip([field[0] for field in fields],[field[2] for field in fields])}
    data = []
    for result in results:
        try:
            data += [[int(field[1](result)) for field in fields]]
        except:
            data += [[field[1](result) for field in fields]]
    return pd.DataFrame(data=data, columns=columns).astype(dtype)


def generate_plot(csv_file_name, plot_file_name, x, y, hue, y_title, xticklabels_rotation=90):
    sns.set(font_scale=1.5)

    sns.set_style("white", {"legend.frameon": True})

    df = pd.read_csv(csv_file_name)

    ax = sns.barplot(data=df, x=x, y=y, hue=hue, palette=sns.color_palette("Paired"))
    ax.set_xlabel('')
    ax.set_ylabel(y_title)

    labels = ax.get_xticklabels()
    ax.set_xticklabels(labels, rotation=xticklabels_rotation)

    fig = ax.get_figure()

    if hue:
        legend = ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', borderaxespad=0.)
        legend.set_label('')

        fig.savefig(plot_file_name, bbox_extra_artists=(legend,), bbox_inches='tight')
        fig.savefig(plot_file_name + '.jpg', bbox_extra_artists=(legend,), bbox_inches='tight')
    else:
        fig.tight_layout()

        fig.savefig(plot_file_name)
        fig.savefig(plot_file_name + '.jpg')

    plt.clf()
    plt.close('all')
