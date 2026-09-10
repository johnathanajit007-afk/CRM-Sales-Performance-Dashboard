import pandas as pd
import os

# Align working directory
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

# Load datasets
try:
    accounts = pd.read_csv(os.path.join('files', 'accounts.csv'))
    products = pd.read_csv(os.path.join('files', 'products.csv'))
    sales_teams = pd.read_csv(os.path.join('files', 'sales_teams.csv'))
    sales_pipeline = pd.read_csv(os.path.join('files', 'sales_pipeline.csv'))
    print("✅ All 4 CSV files loaded successfully!\n")
except FileNotFoundError as e:
    print(f"❌ Error loading files: {e}")
    exit()

# Clean column names
for data in [accounts, products, sales_teams, sales_pipeline]:
    data.columns = data.columns.str.strip().str.lower().str.replace(' ', '_')

# Combine datasets
df = sales_pipeline.merge(sales_teams, on='sales_agent', how='left') \
                   .merge(products, on='product', how='left') \
                   .merge(accounts, on='account', how='left')

print("Columns found in your dataset:")
print(list(df.columns))
print("-" * 50)

# Detect date columns safely
created_cols = [c for c in df.columns if 'create' in c or 'date' in c or 'start' in c]
created_col = created_cols[0] if created_cols else df.columns[0]

close_cols = [c for c in df.columns if 'close' in c or 'end' in c]
close_col = close_cols[0] if close_cols else df.columns[1]

# Format dates
df['created_on'] = pd.to_datetime(df[created_col], errors='coerce')
df['close_date'] = pd.to_datetime(df[close_col], errors='coerce')

# Feature engineering
if 'deal_stage' in df.columns:
    df['is_won'] = df['deal_stage'].astype(str).str.lower().apply(lambda x: 1 if 'won' in x else 0)
    df['is_closed'] = df['deal_stage'].astype(str).str.lower().isin(['won', 'lost']).astype(int)
else:
    df['is_won'] = 0
    df['is_closed'] = 0

df['sales_cycle_days'] = (df['close_date'] - df['created_on']).dt.days
df['close_quarter'] = df['close_date'].dt.to_period('Q')

# Display Data Preview
print("\n=== DATA PREVIEW ===")
print(df.head())

# Save master dataset
df.to_csv('cleaned_crm_sales_master.csv', index=False)
print("\n🎉 Output file saved: 'cleaned_crm_sales_master.csv'")

