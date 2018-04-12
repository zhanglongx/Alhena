# coding: utf-8

import pandas as pd 
import numpy as np
import os

def read_data(data_path, years):
    """ read in datas to feed into lstm
    XXX: 
        1. years must no greater than X shape(n_steps)
        2. X and Y shape(n_samples) should be exactly same
        3. X and Y entries must be exactly same(one on one maped)
        4. some stock may not be included, due to shape reason #1

    data format:
        path_x: n_samples files, each file contains n_channels lines,
                n_steps as years
        path_y: one file as n_samples rows, each file contains two
                columns(stock, labels)

    input: 
        data_path: for LSTM, *NOT* database 
        years: read in num of years, from oldest

    returns:
        X: (n_samples, n_steps, n_channels)
        labels
        n_channels
    """

    # Paths
    path_x = os.path.join(data_path, 'X')
    path_y = os.path.join(data_path, 'Y')

    # Read labels
    label_path = os.path.join(path_, "labels.csv")
    if(not os.path.exists(label_path)):
        raise Exception("label_path doesn't exist")

    labels = pd.read_csv(label_path, header = None)

    # Read time-series data
    files = os.listdir(path_x)
    files.sort()

    # Initiate array
    x = np.zeros((len(labels), n_steps, n_channels))
    i_ch = 0
    for fil_ch in channel_files:
        channel_name = fil_ch[:-posix]
        dat_ = pd.read_csv(os.path.join(path_signals,fil_ch), delim_whitespace = True, header = None)
        X[:,:,i_ch] = dat_.as_matrix()

        # Record names
        list_of_channels.append(channel_name)

        # iterate
        i_ch += 1

    # Return 
    return X, labels[0].values, list_of_channels

