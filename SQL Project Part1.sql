-- 2012년 3월 설립 후 8개월 동안의 성장을 보여주는 데이터 분석

-- 1. 회사의 성장을 보여줄 수 있도록 Gsearch 세션 및 주문에 대한 월별 추세를 보여주세요
select
    year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
	and utm_source = 'gsearch'
group by 1,2;

-- 2. 이번에는 Gsearch에서 nonbrand 캠페인과 brand 캠페인을 따로 분리하여 보여주세요

select
    year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(distinct case when utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as nonbrand_sessions,
    count(distinct case when utm_campaign = 'nonbrand' then orders.order_id else null end) as nonbrand_orders,
    count(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_sessions,
    count(distinct case when utm_campaign = 'brand' then orders.order_id else null end) as brand_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
	and utm_source = 'gsearch'
group by 1,2;

-- 3. Gsearch, nonbrand에서 기기 유형별로 분할된 월별 세션 및 주문을 보여주세요

select
    year(website_sessions.created_at) as yr,
    month(website_sessions.created_at) as mo,
    count(case when device_type = 'desktop' then website_sessions.website_session_id else null end) as desktop_sessions,
    count(case when device_type = 'desktop' then orders.order_id else null end) as desktop_orders,
    count(case when device_type = 'mobile' then website_sessions.website_session_id else null end) as mobile_sessions,
    count(case when device_type = 'mobile' then orders.order_id else null end) as mobile_orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by 1,2;

-- 4. 다른 각 채널에서 월별 트렌드와 함께 Gsearch의 월별 트렌드를 보여주세요

select
    distinct utm_source, utm_campaign, http_referer
from website_sessions
where created_at < '2012-11-27'; -- 채널: gsearch, bsearch, organic_search, direct_type

select
    year(created_at) as yr,
    month(created_at) as mo,
    count(case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_sessions,
    count(case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_sessions,
    count(case when utm_source is null and http_referer is not null then website_session_id else null end) as organic_search_sessions,
    count(case when utm_source is null and http_referer is null then website_session_id else null end) as direct_type_sessions
from website_sessions
where created_at < '2012-11-27';

-- 5. Gsearch, nonbrand landing page 테스트를 통해 얻은 수익을 추정해서 보여주세요
-- /lander-1이 처음 나왔을 때 부터 2012년 7월 28일까지의 CVR 증가를 살펴보고, 
-- 그 이후의 세션 및 수익을 사용하여 증분 값을 보여주세요.

select
    min(website_pageview_id)
from website_pageviews
where pageview_url = '/lander-1';

-- 처음으로 나온 /lander-1의 website_pageview_id는 23504

-- 각 세션의 첫 번째 pageview id 찾기
with cte as (
select
    website_sessions.website_session_id,
    min(website_pageview_id) as first_pageview_id
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_pageview_id >= 23504
	and website_sessions.created_at < '2012-07-28'
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by 1),

-- /home, /lander-1 page 가져오기
cte2 as (
select
    cte.website_session_id,
    pageview_url as landing_page
from cte
	left join website_pageviews
		on cte.first_pageview_id = website_pageviews.website_pageview_id
where pageview_url in ('/home', '/lander-1')),

cte3 as (
select
    cte2.website_session_id,
    cte2.landing_page,
    orders.order_id
from cte2
	left join orders
		on cte2.website_session_id = orders.website_session_id)

-- /home과 /lander-1 간에 전환율 비교
select
    landing_page,
    count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct website_session_id) as conv_rate
from cte3
group by 1;

-- 전환율: /home - 0.0318, /lander-1 - 0.0406 (0.0088 차이)

-- gsearch, nonbrand의 가장 마지막으로 사용된 /home의 세션 아이디 찾기

select
    max(website_sessions.website_session_id)
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at < '2012-11-27'
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
    and pageview_url = '/home';
    
-- gsearch, nonbrand에서 /home의 가장 마지막 세션아이디: 17145

select
    count(website_session_id)
from website_sessions
where created_at < '2012-11-27'
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
    and website_session_id > 17155; -- 마지막 /home 세션
    
-- 마지막 /home세션 다음 부터 2012년 11월 27일 까지 세션의 수는 22,962개
-- 위의 /home과 /lander-1의 전환율 비교로 계산을 해보면 7월 29일 부터 약 202개가 늘었다
-- 한 달마다 주문이 50개 정도의 상승이 있다.

-- 6. 이전에 분석한 랜딩 페이지 테스트의 경우 두 페이지 각각에서 주문까지의 전체 전환 퍼널을 표시해 주세요.
-- 동일하게 /lander-1이 처음 나왔을 때 부터 2012년 7월 28일까지의 기간으로 분석해 주세요.

-- 페이지 확인
select
    distinct pageview_url
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_pageview_id >= 23504
    and website_sessions.created_at < '2012-07-28'
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand';

create temporary table page_1
select
    website_session_id,
    max(homepage) as homepage,
    max(lander1_page) as lander1_page,
    max(products_page) as products_page,
    max(mrfuzzy_page) as mrfuzzy_page,
    max(cart_page) as cart_page,
    max(shipping_page) as shipping_page,
    max(billing_page) as billing_page,
    max(thankyou_page) as thankyou_page
from(
select
    website_sessions.website_session_id,
    case when pageview_url = '/home' then 1 else 0 end as homepage,
    case when pageview_url = '/lander-1' then 1 else 0 end as lander1_page,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_pageview_id >= 23504
    and website_sessions.created_at < '2012-07-28'
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand') as pageview_level
group by 1;

select
    case
	when homepage = 1 then 'homepage'
    when lander1_page = 1 then 'lander1_page'
    end as segment,
    count(website_session_id) as sessions,
    sum(products_page) as to_products,
    sum(mrfuzzy_page) as to_mrfuzzy,
    sum(cart_page) as to_cart,
    sum(shipping_page) as to_shipping,
    sum(billing_page) as to_billing,
    sum(thankyou_page) as to_thankyou
from page_1
group by 1;

-- 클릭률
select
    case
	when homepage = 1 then 'homepage'
    when lander1_page = 1 then 'lander1_page'
    end as segment,
    sum(products_page)/count(website_session_id) as lander_click_rt,
    sum(mrfuzzy_page)/sum(products_page) as products_click_rt,
    sum(cart_page)/sum(mrfuzzy_page) as mrfuzzy_click_rt,
    sum(shipping_page)/sum(cart_page) as cart_click_rt,
    sum(billing_page)/sum(shipping_page) as shipping_click_rt,
    sum(thankyou_page)/sum(billing_page) as billing_click_rt
from page_1
group by 1;

-- 7. 청구 테스트의 영향도 정량화 해주세요
-- 9월 10일 부터 11월 10일 까지의 청구 페이지 세션당 수익 측면에서 생성된 리프트를 분석한 다음
-- 지난 한 달 동안의 청구 페이지 세션 수를 가져와 수익에 미친 영향을 알려주세요.

select
    pageview_url as billing_page,
    count(website_pageviews.website_session_id) as sessions,
    sum(price_usd)/count(website_pageviews.website_session_id) as revenue_per_billing_page
from website_pageviews
	left join orders
		on website_pageviews.website_session_id = orders.website_session_id
where website_pageviews.created_at < '2012-11-10'
    and website_pageviews.created_at > '2012-09-10'
    and pageview_url in ('/billing', '/billing-2')
group by 1;

-- /billing 페이지 - 세션 수 : 657개, 페이지 당 수익 : $22.83
-- /billing-2 페이지 - 세션 수 : 654, 페이지 당 수익 : $31.34
-- 차이 : $8.51

select
    count(website_session_id)
from website_pageviews
where website_pageviews.pageview_url in ('/billing', '/billing-2')
	and created_at between '2012-10-27' and '2012-11-27'
    
-- 지난 한달간 billing 세션의 수는 1193개
-- billing 페이지간 차이가 $8.51이 나기 때문에
-- 따라서 청구 페이지 테스트의 총값은 $10,161이다.
