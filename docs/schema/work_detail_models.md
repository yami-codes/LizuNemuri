# Work Detail Model Schema (Locked)

## WorkInfo — Full work detail (detail screen only)
- Endpoint: `GET /api/workInfo/{id}`
- Response: single `WorkInfo` object
- Design: separate from `Work` model to avoid list-page null pollution

| Field | Type | JSON Key | Description |
|------|------|----------|------|
| id | int | id | Work ID |
| title | String | title | Title |
| circleId | int | circle_id | Circle ID |
| name | String | name | Circle name |
| nsfw | bool | nsfw | NSFW flag |
| release | String | release | Release date |
| dlCount | int | dl_count | Download/sales count |
| price | int | price | Price (JPY) |
| reviewCount | int | review_count | Review count |
| rateCount | int | rate_count | Rating count |
| rateAverage2dp | double | rate_average_2dp | Average rating |
| hasSubtitle | bool | has_subtitle | Has subtitle |
| createDate | String | create_date | Catalog date |
| duration | int | duration | Total duration (seconds) |
| ageCategoryString | String | age_category_string | Age category |
| sourceType | String | source_type | Source type |
| sourceId | String | source_id | Source ID |
| sourceUrl | String | source_url | DLsite URL |
| samCoverUrl | String? | samCoverUrl | Small cover URL |
| thumbnailCoverUrl | String? | thumbnailCoverUrl | Thumbnail URL |
| mainCoverUrl | String? | mainCoverUrl | Main cover URL |
| rateCountDetail | List&lt;RateDetail&gt; | rate_count_detail | Rating distribution |
| rank | List&lt;RankInfo&gt; | rank | Rank info |
| vas | List&lt;WorkVA&gt; | vas | Voice actors |
| tags | List&lt;WorkTag&gt; | tags | Tags (with votes) |
| circle | Circle | circle | Circle detail (reused) |
| languageEditions | List&lt;LanguageEdition&gt;? | language_editions | Language editions |
| translationInfo | TranslationInfo? | translation_info | Translation info |
| originalWorkno | String? | original_workno | Original work number |
| otherLanguageEditionsInDb | List&lt;OtherLanguageEditionsInDb&gt;? | other_language_editions_in_db | Other language editions in DB |
| workAttributes | String? | work_attributes | Work attributes |
| userRating | dynamic | userRating | User rating |

## RateDetail — Rating distribution
| Field | Type | JSON Key | Description |
|------|------|----------|------|
| reviewPoint | int | review_point | Stars 1–5 |
| count | int | count | Count |
| ratio | double | ratio | Ratio (0–100) |

## RankInfo — Rank info
| Field | Type | JSON Key | Description |
|------|------|----------|------|
| term | String | term | "day"/"week"/"month" |
| category | String | category | "all"/"voice" |
| rank | int | rank | Rank |
| rankDate | String | rank_date | Rank date |

## WorkVA — Work voice actor
| Field | Type | Description |
|------|------|------|
| id | String | UUID |
| name | String | Voice actor name |

## WorkTag — Tag with votes (standalone model)
| Field | Type | Description |
|------|------|------|
| id | int | Tag ID |
| name | String | Tag name |
| i18n | I18n? | i18n |
| upvote | int | Upvotes |
| downvote | int | Downvotes |
| voteRank | int | Vote rank |
| voteStatus | int? | User vote state (nullable for guests) |
