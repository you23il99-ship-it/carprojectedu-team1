<%-- 이 페이지의 글자 인코딩을 UTF-8 로 정한다. 빠뜨리면 한글이 깨진다 --%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%-- JSTL 태그를 c: 라는 이름으로 쓰겠다는 선언. 이 줄이 없으면 <c:...> 가 그냥 글자로 나온다 --%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%-- JSTL 태그를 fmt: 라는 이름으로 쓰겠다는 선언. 이 줄이 없으면 <fmt:...> 가 그냥 글자로 나온다 --%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%
    /* Java 코드: 한글 인코딩 설정 */
    request.setCharacterEncoding("UTF-8");
    /* Java 코드: 컨텍스트 경로 얻기 */
    String contextPath = request.getContextPath();
    /*
     [AI 예약 비서 연동] 주소로 미리 채울 값이 넘어올 수 있다.
       "말로 예약" 탭에서 "예약 이어가기"를 누르면
           /Car/CarInfo.do?carno=3&carqty=2&carbegindate=2026-08-07&carreserveday=3
       처럼 조건이 붙어서 들어온다. 그 값으로 수량을 미리 선택해 주고,
       시작일/일수는 다음 화면(CarOption.jsp)까지 hidden 으로 전달한다.
     [보안] 주소의 파라미터는 사용자가 마음대로 바꿀 수 있는 값이다.
            화면에 넣기 전에 "형식이 맞는 값만" 통과시킨다.
            (날짜는 YYYY-MM-DD, 숫자는 숫자만 - 아니면 없는 것으로 취급)
    */
    String prefillQty   = request.getParameter("carqty");
    // 화면에서 넘어온 carbegindate 값을 꺼내 prefillBegin 에 담는다. 없으면 null 이 들어온다
    String prefillBegin = request.getParameter("carbegindate");
    // 화면에서 넘어온 carreserveday 값을 꺼내 prefillDays 에 담는다. 없으면 null 이 들어온다
    String prefillDays  = request.getParameter("carreserveday");
    // qtySelected — 숫자 1 을 담는다
    int qtySelected = 1;
    // 조건을 확인해 맞을 때만 아래를 실행한다
    if (prefillQty != null && prefillQty.matches("[1-5]")) {
        // qtySelected 에 parseInt( ) 의 결과를 담는다
        qtySelected = Integer.parseInt(prefillQty);
    }
    // 값이 비어 있는지 먼저 확인한다. 비었는데 그냥 쓰면 프로그램이 멈춘다
    if (prefillBegin == null || !prefillBegin.matches("\\d{4}-\\d{2}-\\d{2}")) {
        // prefillBegin 에 글자값 "" 을 담는다
        prefillBegin = "";
    }
    // 값이 비어 있는지 먼저 확인한다. 비었는데 그냥 쓰면 프로그램이 멈춘다
    if (prefillDays == null || !prefillDays.matches("\\d{1,2}")) {
        // prefillDays 에 글자값 "" 을 담는다
        prefillDays = "";
    }
    //아래 JSTL(${qtyPre})에서 쓸 수 있도록 페이지 영역에 담아둔다
    pageContext.setAttribute("qtyPre", qtySelected);
%>
<%--
 ================================================================================
   CarInfo.jsp  -  차량 상세 + 대여 수량 선택 (예약 흐름 1단계)
   [6단계 전면 재작성]
   (기존 화면의 문제)
     문제1. 실제 차량 사진을 쓰지 않았다.
            img 폴더에 사진이 있는데도 이모지 플레이스홀더를 보여줬다.
                <span class="car-icon">🚗</span>
            차를 확정하는 화면에서 사진이 없으면 무엇을 예약하는지 확신할 수 없다.
     문제2. DB 값을 가공 없이 그대로 노출했다.
                대여금액  : 45000        <- 천단위 쉼표가 없어 자릿수를 헷갈린다
                차량분류  : Small        <- 영문 코드가 사용자에게 그대로 보였다
            탑승 인원(carusepeople)은 DB 에 있는데도 보여주지 않았다.
            정작 차를 고를 때 가장 중요한 정보 중 하나다.
     문제3. 표(table) 레이아웃 + 고정 너비라 모바일에서 라벨이 눌렸다.
   (지금)
     - 실제 사진 + 등급 배지
     - 45,000원 / "소형 · 준중형" / 5인승 처럼 사람이 읽는 형태로 표시
     - label + form-control 로 바꿔 모바일에서 위아래로 쌓인다
     - 다음 화면(옵션 선택)에서도 사진을 쓸 수 있도록 carname 을 함께 전달
 ================================================================================
--%>
<div class="container">
	<%-- section-head 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
	<div class="section-head">
		<%-- 글자 묶음 — CSS 로 모양을 입히는 용도 --%>
		<span class="section-eyebrow">STEP 1 / 3</span>
		<%-- 제목 --%>
		<h2 class="section-heading">차량 정보</h2>
		<%-- 문단 글 --%>
		<p class="section-desc">대여 수량을 정하고 옵션 선택으로 이동하세요</p>
	</div>
	<%-- 조회된 차량 정보를 보고 대여수량을 선택해 옵션 선택 화면을 요청한다 --%>
	<form action="<%=contextPath%>/Car/CarOption.do" method="post">
		<%-- [보안] CSRF 토큰 : 이 화면에서 출발한 요청임을 증명한다 (설명은 members/login.jsp) --%>
		<input type="hidden" name="_csrf" value="${_csrf}">
		<%-- 옵션 선택 화면으로 예약할 차번호 / 사진 / 요금을 전달 --%>
		<input type="hidden" name="carno"    value="${requestScope.vo.carno}">
		<%-- 화면에는 안 보이지만 서버로 함께 보낼 carimg 값 --%>
		<input type="hidden" name="carimg"   value="${requestScope.vo.carimg}">
		<%-- 화면에는 안 보이지만 서버로 함께 보낼 대여요금 값 --%>
		<input type="hidden" name="carprice" value="${requestScope.vo.carprice}">
		<%-- [추가] 다음 화면에서 차량명을 보여주기 위해 함께 전달 --%>
		<input type="hidden" name="carname"  value="${requestScope.vo.carname}">
		<%-- [AI 예약 비서 연동] 시작일/일수를 옵션 화면까지 전달한다 (값이 없으면 빈 문자열) --%>
		<input type="hidden" name="prefillBegin" value="<%=prefillBegin%>">
		<%-- 화면에는 안 보이지만 서버로 함께 보낼 prefillDays 값 --%>
		<input type="hidden" name="prefillDays"  value="<%=prefillDays%>">
		<%-- grid-2 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
		<div class="grid-2">
			<%-- ================= 왼쪽 : 차량 사진 ================= --%>
			<div class="card">
				<%-- car-photo 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
				<div class="car-photo">
					<%-- 이미지를 화면에 보여준다 --%>
					<img src="<%=contextPath%>/img/${requestScope.vo.carimg}"
						 alt="${requestScope.vo.carname} 차량 사진">
					<%-- 등급 배지 : 색으로 소형/중형/대형을 구분 --%>
					<c:choose>
						<%-- ${requestScope.vo.carcategory eq  일 때 그릴 내용 --%>
						<c:when test="${requestScope.vo.carcategory eq 'Small'}">
							<%-- 글자 묶음 — CSS 로 모양을 입히는 용도 --%>
							<span class="car-badge car-badge-small">소형</span>
						</c:when>
						<%-- ${requestScope.vo.carcategory eq  일 때 그릴 내용 --%>
						<c:when test="${requestScope.vo.carcategory eq 'Mid'}">
							<%-- 글자 묶음 — CSS 로 모양을 입히는 용도 --%>
							<span class="car-badge car-badge-mid">중형</span>
						</c:when>
						<%-- 위 조건이 전부 아닐 때 그릴 내용 --%>
						<c:otherwise>
							<%-- 글자 묶음 — CSS 로 모양을 입히는 용도 --%>
							<span class="car-badge car-badge-big">대형</span>
						</c:otherwise>
					</c:choose>
				</div>
			</div>
			<%-- ================= 오른쪽 : 상세 정보 + 수량 ================= --%>
			<div>
				<%-- 작은 제목 --%>
				<h3 class="car-name" style="font-size:var(--fs-2xl); margin-bottom:var(--sp-3);">
					${requestScope.vo.carname}
				</h3>
				<%-- car-meta mb-4 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
				<div class="car-meta mb-4">
					<%-- 글자 묶음 — CSS 로 모양을 입히는 용도 --%>
					<span>${requestScope.vo.carcompany}</span>
					<%-- 글자 묶음 — CSS 로 모양을 입히는 용도 --%>
					<span>${requestScope.vo.carusepeople}인승</span>
					<%-- 영문 코드(Small/Mid/Big)를 사용자가 읽는 말로 바꿔 표시한다 --%>
					<span>
						<%-- 여러 갈래 중 하나만 그린다. 아래 when·otherwise 로 갈래를 적는다 --%>
						<c:choose>
							<%-- ${requestScope.vo.carcategory eq  일 때 그릴 내용 --%>
							<c:when test="${requestScope.vo.carcategory eq 'Small'}">소형 · 준중형</c:when>
							<%-- ${requestScope.vo.carcategory eq  일 때 그릴 내용 --%>
							<c:when test="${requestScope.vo.carcategory eq 'Mid'}">중형 · SUV</c:when>
							<%-- 위 조건이 전부 아닐 때 그릴 내용 --%>
							<c:otherwise>대형 · 승합</c:otherwise>
						</c:choose>
					</span>
				</div>
				<%-- 이름-내용 짝 목록 --%>
				<dl class="detail-list mb-4">
					<%-- detail-row 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
					<div class="detail-row">
						<%-- 항목의 이름 --%>
						<dt>1일 대여료</dt>
						<%-- 항목의 내용 --%>
						<dd>
							<%-- 굵게 강조 --%>
							<strong class="text-brand" style="font-size:var(--fs-xl);">
								<fmt:formatNumber value="${requestScope.vo.carprice}" pattern="#,###"/>원
							</strong>
							<%-- 글자 묶음 — CSS 로 모양을 입히는 용도 --%>
							<span class="text-muted fs-sm">/ 1대</span>
						</dd>
					</div>
					<%-- detail-row 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
					<div class="detail-row">
						<%-- 항목의 이름 --%>
						<dt>탑승 인원</dt>
						<%-- 항목의 내용 --%>
						<dd>최대 ${requestScope.vo.carusepeople}명</dd>
					</div>
					<%-- detail-row 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
					<div class="detail-row">
						<%-- 항목의 이름 --%>
						<dt>제조사</dt>
						<%-- 항목의 내용 --%>
						<dd>${requestScope.vo.carcompany}</dd>
					</div>
				</dl>
				<%-- form-group 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
				<div class="form-group">
					<%-- 입력칸에 붙는 이름표 --%>
					<label class="form-label" for="carqty">대여 수량</label>
					<%-- 여러 개 중 하나를 고르는 목록 상자 — 서버로 "carqty" 이름으로 전송 --%>
					<select class="form-control" id="carqty" name="carqty">
						<%-- AI 예약 비서가 계산해 준 대수(qtyPre)가 있으면 미리 선택해 둔다 --%>
						<c:forEach var="q" begin="1" end="5">
							<%-- Controller 가 "q" 이름으로 실어 보낸 값을 화면에 찍는다 --%>
							<option value="${q}" <c:if test="${q == qtyPre}">selected</c:if>>${q}대</option>
						</c:forEach>
					</select>
					<%-- 문단 글 --%>
					<p class="form-hint">여러 대가 필요하면 수량을 늘려주세요</p>
				</div>
				<%-- flex flex-wrap gap-2 mt-6 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
				<div class="flex flex-wrap gap-2 mt-6">
					<%-- 누르면 동작하는 버튼 --%>
					<button type="submit" class="btn btn-primary btn-lg">옵션 선택하기 &rsaquo;</button>
					<%-- 다른 화면으로 넘어가는 링크 --%>
					<a class="btn btn-ghost" href="<%=contextPath%>/Car/CarList.do">&lsaquo; 목록으로</a>
				</div>
			</div>
		</div>
	</form>
	<%-- 차량 설명 : DB 의 carinfo 값 --%>
	<c:if test="${not empty requestScope.vo.carinfo}">
		<%-- section-soft mt-8 모양을 입힐 영역. 실제 모양은 CSS 에서 정한다 --%>
		<div class="section-soft mt-8">
			<%-- 작은 제목 --%>
			<h3 class="fw-bold mb-2">차량 안내</h3>
			<%-- 문단 글 --%>
			<p class="text-muted">${requestScope.vo.carinfo}</p>
		</div>
	</c:if>
</div>