import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# One blue color used everywhere so every chart matches.
BLUE_DARK  = "#0B3C5D"
BLUE_MID   = "#1D6FA3"
BLUE_LIGHT = "#4FA6DA"

sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 110
plt.rcParams['axes.titlesize'] = 13
plt.rcParams['axes.titleweight'] = 'bold'

# Load the data
df = pd.read_csv('/Users/suryadevrathjayakumar/Downloads/final_amazon.csv')
print("Total rows and columns:", df.shape)

# About 2,000 rows don't have pricing info so we can't calculate a
# discount for them. We drop those rows into their own table (price_df)
# and use that table for every analysis that involves money.
price_df = df.dropna(subset=['current_price', 'listed_price', 'discount_percentage']).copy()
price_df['purchased_last_month_est'] = price_df['purchased_last_month_est'].fillna(0)
price_df['revenue_proxy'] = price_df['current_price'] * price_df['purchased_last_month_est']



# ANALYSIS 1: Exploratory Data Analysis (EDA)

print("\n===== ANALYSIS 1: Exploratory Data Analysis =====")
print(df.isnull().sum())
print(df.describe())

fig, axes = plt.subplots(2, 2, figsize=(13, 9))

sns.histplot(df['rating'].dropna(), bins=20, kde=False, ax=axes[0, 0], color=BLUE_MID)
axes[0, 0].set_title("How are ratings distributed?")

sns.histplot(price_df['discount_percentage'], bins=30, kde=False, ax=axes[0, 1], color=BLUE_DARK)
axes[0, 1].set_title("How are discounts distributed?")

sns.histplot(np.log1p(price_df['current_price']), bins=30, kde=False, ax=axes[1, 0], color=BLUE_LIGHT)
axes[1, 0].set_title("How are prices distributed? (log scale)")
axes[1, 0].set_xlabel("log(1 + current_price)")

cat_counts = df['category'].value_counts()
sns.barplot(x=cat_counts.values, y=cat_counts.index, color=BLUE_MID, ax=axes[1, 1])
axes[1, 1].set_title("How many products per category?")

plt.tight_layout()
plt.savefig('01_eda_overview.png', bbox_inches='tight')
plt.show()

print("What this tells us: most products are rated 4-5 stars, most have")
print("no discount at all, and 'Other Electronics' is the biggest category.")


# ANALYSIS 2: Discount Threshold Analysis

# The question here: as discounts get bigger, do products actually sell
# more? We are grouping products into discount ranges and compare average
# purchases and best-seller rate across those ranges.

print("\n===== ANALYSIS 2: Discount Threshold Analysis =====")
bins = [-0.1, 0, 10, 20, 30, 40, 50, 100]
labels = ['0%', '0-10%', '10-20%', '20-30%', '30-40%', '40-50%', '50%+']
price_df['discount_range'] = pd.cut(price_df['discount_percentage'], bins=bins, labels=labels)

threshold_summary = price_df.groupby('discount_range', observed=True).agg(
    product_count=('title', 'count'),
    avg_purchases=('purchased_last_month_est', 'mean'),
    best_seller_rate=('is_best_seller', 'mean')
).round(2)
print(threshold_summary)

fig, axes = plt.subplots(1, 2, figsize=(13, 5))

threshold_summary['avg_purchases'].plot(kind='bar', ax=axes[0], color=BLUE_DARK)
axes[0].set_title("Average monthly purchases by discount range")
axes[0].tick_params(axis='x', rotation=40)

(threshold_summary['best_seller_rate'] * 100).plot(kind='bar', ax=axes[1], color=BLUE_LIGHT)
axes[1].set_title("Best-seller rate (%) by discount range")
axes[1].tick_params(axis='x', rotation=40)

plt.tight_layout()
plt.savefig('02_discount_threshold.png', bbox_inches='tight')
plt.show()

print("What this tells us: the 10-20% and 40-50% discount ranges get the")
print("most purchases on average — that looks like the 'sweet spot'.")



# ANALYSIS 3: Discount vs Revenue Analysis
# Does giving a bigger discount actually bring in
# more revenue or is it just giving away margin for nothing? We check
# this using a scatter plot and a correlation number.

print("\n===== ANALYSIS 3: Discount vs Revenue Analysis =====")
sample = price_df.sample(min(4000, len(price_df)), random_state=42)

plt.figure(figsize=(8, 5))
sns.regplot(data=sample, x='discount_percentage', y='revenue_proxy',
            scatter_kws={'alpha': 0.15, 's': 10, 'color': BLUE_LIGHT},
            line_kws={'color': BLUE_DARK})
plt.yscale('log')
plt.title("Discount % vs estimated revenue (log scale)")
plt.tight_layout()
plt.savefig('03_discount_vs_revenue.png', bbox_inches='tight')
plt.show()

corr_value = price_df['discount_percentage'].corr(price_df['revenue_proxy'])
print(f"Correlation between discount % and estimated revenue: {corr_value:.3f}")
print("What this tells us: this number is very close to 0, meaning bigger")
print("discounts are NOT reliably bringing in more revenue.")


# ANALYSIS 4: Category-wise Profitability Analysis

# Which product categories are actually bringing in the most estimated
# revenue and how much discount are they relying on to get there?

print("\n===== ANALYSIS 4: Category-wise Profitability Analysis =====")
cat_summary = price_df.groupby('category').agg(
    avg_discount=('discount_percentage', 'mean'),
    total_revenue_proxy=('revenue_proxy', 'sum')
).round(2).sort_values('total_revenue_proxy', ascending=False)
print(cat_summary)

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

cat_summary['total_revenue_proxy'].plot(kind='barh', ax=axes[0], color=BLUE_DARK)
axes[0].set_title("Total estimated revenue by category")
axes[0].invert_yaxis()

cat_summary['avg_discount'].sort_values().plot(kind='barh', ax=axes[1], color=BLUE_LIGHT)
axes[1].set_title("Average discount % by category")

plt.tight_layout()
plt.savefig('04_category_profitability.png', bbox_inches='tight')
plt.show()

best_category = cat_summary['total_revenue_proxy'].idxmax()
worst_category = cat_summary['total_revenue_proxy'].idxmin()
print(f"What this tells us: {best_category} brings in the most estimated")
print(f"revenue, while {worst_category} brings in the least.")

print("\nAll done. Four charts have been saved as PNG files in this folder.")