import numpy as np

def find_anomalies(random_data):
    # Function to Detection Outlier on one-dimentional datasets.
    # cut off the top and bottom 0.25% of subjects (as recommended in the ABCD 2.0.1 documentation)
    anomalies=[]
    cutoff = 2.80703    # z score corresponds to top and bottom 0.25% of data
    # Set upper and lower limit to 3 standard deviation
    random_data_std = np.std(random_data)
    random_data_mean = np.mean(random_data)
    anomaly_cut_off = random_data_std * cutoff
    
    lower_limit  = random_data_mean - anomaly_cut_off 
    upper_limit = random_data_mean + anomaly_cut_off
    # print(lower_limit)

    # Generate list of outliers
    for outlier in random_data:
        if outlier > upper_limit or outlier < lower_limit:
            anomalies.append(outlier)
    return [anomalies,upper_limit,lower_limit]