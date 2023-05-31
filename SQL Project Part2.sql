-- 회사가 설립된지 3년이 되었고, 지금까지의 데이터를 통해 회사의 성장을 분석

-- 1. 볼륨 성장을 보여주기 위해 분기별로 전체 세션 및 주문량을 보여주세요

select
    year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

-- 2. 다음으로 분기별로 세션-주문 전환율, 주문당 수익 및 세션당 수익에 대해 보여주세요

select
    year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(orders.order_id)/count(website_sessions.website_session_id) as session_to_order_conv_rate,
    sum(price_usd)/count(orders.order_id) as revenue_per_order,
    sum(price_usd)/count(website_sessions.website_session_id) as revenue_per_session
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

-- 3. 각 채널에 대한 전체 세션 세션-주문 전환율 추세를 분기별로 보여주세요

select
    year(website_sessions.created_at) as yr,
    quarter(website_sessions.created_at) as qtr,
    count(case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)
		/ count(case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as gsearch_nonbrand_conv_rt,
    count(case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)
		/ count(case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as bsearch_nonbrand_conv_rt,
	count(case when utm_campaign = 'brand' then orders.order_id else null end)
		/ count(case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_search_conv_rt,
	count(case when utm_source is null and http_referer is not null then orders.order_id else null end)
		/ count(case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_conv_rt,
    count(case when utm_source is null and http_referer is null then orders.order_id else null end)
		/ count(case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_type_conv_rt
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

-- 4. 총 판매 및 수익과 함께 제품별 수익 및 마진에 대한 월별 추세를 보여주세요

select
    year(created_at) as yr,
    month(created_at) as mo,
    sum(case when product_id = 1 then price_usd else null end) as mrfuzzy_rev,
    sum(case when product_id = 1 then price_usd - cogs_usd else null end) as mrfuzzy_marg,
    sum(case when product_id = 2 then price_usd else null end) as lovebear_rev,
    sum(case when product_id = 2 then price_usd - cogs_usd else null end) as lovebear_marg,
    sum(case when product_id = 3 then price_usd else null end) as birthdaybear_rev,
    sum(case when product_id = 3 then price_usd - cogs_usd else null end) as birthdaybear_marg,
    sum(case when product_id = 4 then price_usd else null end) as minibear_rev,
    sum(case when product_id = 4 then price_usd - cogs_usd else null end) as minibear_marg,
    sum(price_usd) as total_revenue,
    sum(price_usd - cogs_usd) as total_margin
from order_items
group by 1,2;

-- 5. 신제품 출시의 영향에 대해 알아보기 위해 월별 세션을 /products 페이지로 가져오고 
-- 다른 페이지를 통해 클릭하는 세션의 %가 시간 경과에 따라 어떻게 변했는지
-- 보여주고, /products에서 주문으로의 전환을 보여주세요

-- 먼저 /products 페이지의 모든 보기를 식별한다.
with cte as (
select
    website_session_id,
    website_pageview_id,
    created_at
from website_pageviews
where pageview_url = '/products')

select
    year(cte.created_at) as yr,
    month(cte.created_at) as mo,
    count(distinct cte.website_session_id) as sessions_to_product_page,
    count(distinct website_pageviews.website_session_id) as clicked_to_next_page,
    count(distinct website_pageviews.website_session_id)/count(distinct cte.website_session_id) as clickthrough_rt,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct cte.website_session_id) as products_to_order_rt
from cte
	left join website_pageviews
		on cte.website_session_id = website_pageviews.website_session_id
        and website_pageviews.website_pageview_id > cte.website_pageview_id
	left join orders
		on orders.website_session_id = cte.website_session_id
group by 1,2;
 
-- 6. 2014년 12월 5일에 4번째 제품을 기본 제품으로 제공했습니다
-- 그 이후의 판매 데이터를 가져와서 각 제품이 서로 얼마나 잘 교차 판매되는지 보여주세요

with cte as (
select
    order_id,
    primary_product_id,
    created_at
from orders
where created_at > '2014-12-05')

select
    primary_product_id,
    count(distinct order_id) as total_orders,
    count(distinct case when cross_sell_product_id = 1 then order_id else null end) as cross_sold_p1,
    count(distinct case when cross_sell_product_id = 2 then order_id else null end) as cross_sold_p2,
    count(distinct case when cross_sell_product_id = 3 then order_id else null end) as cross_sold_p3,
    count(distinct case when cross_sell_product_id = 4 then order_id else null end) as cross_sold_p4,
    count(distinct case when cross_sell_product_id = 1 then order_id else null end)/count(distinct order_id) as p1_cross_sell_rt,
    count(distinct case when cross_sell_product_id = 2 then order_id else null end)/count(distinct order_id) as p2_cross_sell_rt,
    count(distinct case when cross_sell_product_id = 3 then order_id else null end)/count(distinct order_id) as p3_cross_sell_rt,
    count(distinct case when cross_sell_product_id = 4 then order_id else null end)/count(distinct order_id) as p4_cross_sell_rt
from(
select
	cte.*,
    order_items.product_id as cross_sell_product_id
from cte
	left join order_items
		on cte.order_id = order_items.order_id
        and order_items.is_primary_item = 0) as primary_cross_sell
group by 1;
