import os
import pandas as pd
import glob
from pathlib import Path

data_frames = []
# use Converters to maintain the leading zeros for columns such as Client ID and Sub ID.
for f in glob.glob("*.xlsx"):
    df = pd.read_excel(f, converters={
                            "Client ID": str,
                            "Client Sub-ID": str,
                            })
    df['ClientType'] = Path(f).stem
    data_frames.append(df)

all_data = pd.concat(data_frames, ignore_index=True)

print(all_data.head())
all_data.to_excel('Axcess Clients.xlsx', index=False, sheet_name='Axcess Clients')
