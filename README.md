# Diamond Sales Analysis

An end-to-end data analysis project examining the factors that influence diamond selling prices, sales performance, customer behavior, and market segmentation.

The project combines data preprocessing, exploratory data analysis, subgroup comparison, statistical hypothesis testing, machine learning, and Tableau visualizations to generate practical business insights from diamond sales data.

## Project Overview

The analysis was conducted on a diamond sales dataset covering the period from 2022 to 2024. After cleaning and validation, the final dataset contained **4,499 records and 19 variables** describing diamond characteristics, prices, appraisal values, discounts, sales channels, certifications, customer satisfaction, and sales performance.

The project was designed to answer the following questions:

- Which characteristics have the strongest relationship with diamond selling price?
- How do Cut, Color, Clarity, and Carat affect pricing?
- How closely do selling prices correspond to appraisal values?
- How does performance differ across sales channels?
- Why do Standard diamonds initially appear more expensive than Premium diamonds?
- Is the controlled price difference between Premium and Standard diamonds statistically significant?
- Can diamond prices be predicted accurately using Linear Regression?
- Can diamonds be divided into meaningful market segments using K-Means clustering?

## Technologies Used

- Python
- Jupyter Notebook
- pandas
- NumPy
- Matplotlib
- Seaborn
- SciPy
- scikit-learn
- Tableau

## Project Workflow

### 1. Data Preprocessing

The preprocessing stage included:

- Inspecting column types, missing values, unique values, and distributions
- Converting incorrectly formatted numerical fields
- Processing inconsistent date formats
- Standardizing categorical values and certification names
- Detecting invalid and unrealistic observations
- Correcting the discount-percentage calculation
- Handling missing numerical and categorical values
- Investigating duplicate records and identifiers
- Removing two confirmed erroneous Carat observations
- Preserving legitimate high-value business outliers
- Performing final validation and exporting the cleaned dataset

The final cleaned dataset contained **4,499 rows**, with no missing values or fully duplicated records.

### 2. Exploratory Data Analysis

The exploratory analysis examined:

- Carat weight and selling price
- The effects of Cut, Color, and Clarity
- Selling price compared with appraisal value
- Discount behavior across sales channels and Carat groups
- Sales-channel performance
- High-price outliers
- Monthly and annual sales trends
- Correlations among numerical and ordinal characteristics

### 3. Subgroup and Deep Analysis

Premium and Standard diamonds were compared across selling price, Carat weight, appraisal value, discount percentage, customer satisfaction, and days on market.

The initial analysis showed that Standard diamonds had a higher overall average selling price. Further investigation demonstrated that this unexpected result was largely explained by their higher average Carat weight.

Comparing the groups within similar Carat ranges produced a more meaningful assessment of the effect of Cut quality.

### 4. Statistical Hypothesis Testing

Welch's independent-samples t-test was used to compare the mean selling prices of Premium and Standard diamonds within the **1–1.5 Carat** range.

| Metric | Result |
|---|---:|
| Premium sample size | 675 |
| Standard sample size | 345 |
| Mean price difference | $310.87 |
| T-statistic | 1.9083 |
| P-value | 0.0568 |
| Cohen's d | 0.126 |

At a significance level of 0.05, the null hypothesis was not rejected. The observed price difference was not statistically significant and had a very small practical effect size.

### 5. Linear Regression

A baseline Linear Regression model was developed to predict selling price using physical measurements and quality characteristics.

Because diamond prices were strongly right-skewed, a second model was trained using a logarithmic transformation of the target variable.

| Metric | Baseline Model | Final Log-Transformed Model |
|---|---:|---:|
| Test R² | 0.9259 | **0.9507** |
| MAE | $721.00 | **$458.54** |
| RMSE | $1,066.45 | **$869.88** |
| MAPE | 37.88% | **10.90%** |
| Median APE | 19.67% | **9.27%** |
| WAPE | 18.06% | **11.49%** |
| Negative predictions | 64 | **0** |

Five-fold cross-validation produced a mean R² of **0.9505** with a standard deviation of **0.0039** for the final model, indicating stable performance across different data partitions.

Permutation importance identified Carat weight as the most influential predictor, followed by physical dimensions and several Clarity categories.

### 6. K-Means Clustering

K-Means clustering was applied after standardizing the numerical features. The Elbow Method supported a three-cluster solution:

- **Entry-Level Diamonds** — smaller diamonds with lower selling prices
- **Mid-Value Diamonds** — moderately sized diamonds with intermediate prices
- **Premium Diamonds** — larger diamonds with substantially higher prices

| Evaluation Metric | Result |
|---|---:|
| Silhouette Score | 0.381 |
| Davies-Bouldin Score | 1.042 |

The results indicate a moderate and interpretable clustering structure. These segments can support inventory planning, product positioning, pricing strategies, and targeted marketing.

## Key Findings

- Carat weight was the strongest driver of diamond selling price.
- Carat and selling price had a Pearson correlation of approximately **0.919**.
- Selling price and appraisal value had a correlation of approximately **0.997**.
- Approximately **91%** of diamonds were sold below their appraised value.
- Raw quality-group comparisons were strongly affected by differences in Carat weight.
- Annual sales volume increased from **1,228 diamonds in 2022** to **1,693 in 2024**.
- Total sales value increased from approximately **$5.02 million** to **$6.82 million**.
- The log-transformed regression model substantially improved prediction accuracy.
- K-Means identified three useful broad market segments, although some overlap remained between neighboring clusters.

## Business Recommendations

- Use the final regression model as a pricing-support tool rather than a replacement for professional appraisal.
- Compare quality groups within similar Carat ranges to avoid misleading conclusions.
- Use the market segments to support inventory organization, product positioning, and targeted marketing.
- Review exceptional high-value diamonds individually because their absolute prediction errors may be larger.
- Continue monitoring sales growth and potential end-of-year seasonality using additional years of data.

## Repository Contents

```text
diamond-sales-analysis/
├── README.md
├── LICENSE
├── .gitignore
├── requirements.txt
├── diamond_sales_analysis.ipynb
├── diamond_sales_analysis_presentation.pdf
└── diamond_sales_clean.csv
```

## How to Run the Project

1. Clone the repository:

```bash
git clone https://github.com/shaialt/diamond-sales-analysis.git
```

2. Enter the project directory:

```bash
cd diamond-sales-analysis
```

3. Install the required libraries:

```bash
pip install -r requirements.txt
```

4. Open the Jupyter Notebook:

```bash
jupyter notebook diamond_sales_analysis.ipynb
```

Before running the notebook, ensure that the dataset filename and path in the data-loading cell match the CSV file included in the repository.

## Tableau Visualizations

The presentation includes a Tableau appendix covering:

- Diamond Color distribution
- Diamond Clarity distribution
- Diamond price by Carat
- Certification distribution
- Sales-channel distribution

**Tableau Public:** [View the interactive visualizations](https://public.tableau.com/app/profile/shai.levi.altshtein/vizzes)

## Limitations

- The dataset covers a limited period from 2022 to 2024.
- Observed relationships should not automatically be interpreted as causal.
- Some predictors, including Carat weight and physical dimensions, are strongly correlated.
- The K-Means clusters have moderate rather than perfect separation.
- Exceptional and high-value diamonds may still require professional appraisal and market judgment.

## Author

**Shai Levi Altshtein**

Data Analysis | Python | SQL | Tableau | Machine Learning

## License

Copyright © 2026 Shai Levi Altshtein. All rights reserved.

This project is publicly available solely for portfolio evaluation and educational review. Copying, modification, redistribution, republication, commercial use, or presentation of this work as one's own is prohibited, except for the limited functionality required by GitHub's Terms of Service.

See the [LICENSE](LICENSE) file for the complete terms.