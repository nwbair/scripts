import os
import pandas as pd
import glob
from pathlib import Path

all_data = pd.DataFrame()
# use Converters to maintain the leading zeros for columns such as Client ID and Sub ID.
for f in glob.glob("*.xlsx"):
    df = pd.read_excel(f, converters={
                            "Client ID": str,
                            "Client Sub-ID": str,
                            })
    df['ClientType'] = Path(f).stem
    all_data = all_data.append(df, ignore_index=True)

all_data.head()
all_data.to_excel('Axcess Clients.xlsx', index=False, sheet_name='Axcess Clients')
