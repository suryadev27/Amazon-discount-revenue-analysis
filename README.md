**Amazon Product Discount & Revenue Analysis**

Objective
Analyze the relationship between discount depth, product category and estimated revenue to determine whether discounting is an effective lever for growth, identify which discount ranges perform best and highlight which categories are discounting heavily without the results to show for it.

Tools Used
- SQL (data cleaning)
- Python (pandas, matplotlib, seaborn)
- Power BI

Dataset from kaggle
41,713 Amazon products across 16 categories, including price, discount percentage, rating, category, best-seller status, sponsorship, and coupon data.

Important note on "revenue" and "profit": In this dataset does not include seller cost data, so true profit margin cannot be calculated. Wherever "Revenue Proxy" appears in this project, it refers to an estimate built as:

Revenue Proxy = current_price × estimated monthly purchases

This is a stand-in for revenue based on price and estimated purchase volume — not verified accounting profit. All findings below should be read with this in mind.

Dashboard Preview
https://app.powerbi.com/groups/me/reports/48f7dfe6-da97-4d80-900d-2c4dd4344e5e/3526fcd527eaaeb56975?experience=power-bi

Analysis Performed
- SQL-based data cleaning (handling nulls, standardizing price and discount fields)
- Exploratory Data Analysis (EDA)
- Discount threshold analysis
- Discount vs revenue analysis
- Category-wise profitability analysis
- Interactive Power BI dashboard (3 pages: Overview, Discount Performance, Category Profitability)

Key Insights
- 70% of products carry no discount at all; where discounts exist, most are under 20%
- The 10–20% and 40–50% discount ranges show the highest average purchases — a likely "sweet spot"
- Correlation between discount % and estimated revenue is **~0.03**, essentially flat — deeper discounts do not reliably translate into more revenue
- Power & Batteries** generates the highest estimated revenue ($293M) while relying on a below-average discount rate (~8.3%)
- Chargers & Cables** has the highest average discount (~14%) but ranks only 8th in estimated revenue — discounting heavily without a proportional payoff
- Optics & Outdoor** generates the lowest estimated revenue despite having the highest average price per item

Business Recommendations
- Move away from blanket discounting; target the 10–20% and 40–50% ranges where purchase lift is strongest
- Reduce discount depth in Chargers & Cables and reallocate that margin toward categories like Power & Batteries or Headphones
- Protect margin in already-strong categories (Power & Batteries) rather than promoting them with deeper discounts
- Evaluate discount strategy per category rather than applying uniform discount rules catalog-wide
- Treat "revenue proxy" figures as directional estimates for prioritization, not confirmed profit figures, until real cost data is available

Project Files
- Data_cleaning_Amazon_products.sql — initial data cleaning of the raw Amazon product dataset (deduplication, type conversion, discount calculation, category classification)
- amazon_analysis_final.py — full Python analysis (EDA, discount threshold, discount vs revenue, category profitability)
- Chart PNGs generated from the Python script
- Power BI .pbix dashboard file
- Dashboard screenshots
