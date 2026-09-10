<%-- 이 페이지의 글자 인코딩을 UTF-8 로 정한다. 빠뜨리면 한글이 깨진다 --%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%
    // (1) 한글 인코딩 설정. POST 파라미터 한글 깨짐 방지
    request.setCharacterEncoding("UTF-8");

    // (2) 컨텍스트 경로 얻기. 실제 주소를 위한 contextPath값
    String contextPath = request.getContextPath();

    // (3) CSRF 토큰값 처리 (requestScope에서 가져옴, null체크 포함)
    Object csrfObj = request.getAttribute("_csrf");
    String csrf = csrfObj != null ? csrfObj.toString() : "";

    // (4) 예약 정보 객체(vo) 읽기 (requestScope에서 가져옴)
    Object voObj = request.getAttribute("vo");

    // (5) 총 차량금액과 옵션금액 얻기 (requestScope에서 가져옴, null시 0)
    Object totalreserveObj = request.getAttribute("totalreserve"); // 차량
    Object totaloptionObj = request.getAttribute("totaloption");   // 옵션
    int totalreserve = (totalreserveObj != null) ? Integer.parseInt(totalreserveObj.toString()) : 0;
    int totaloption = (totaloptionObj != null) ? Integer.parseInt(totaloptionObj.toString()) : 0;

    // (6) 차량명(이름) 파라미터 값 읽기
    String carname = request.getParameter("carname");

    // (7) vo에서 개별 예약항목 값 추출 (모두 null 또는 기본값 처리)
    Integer carno = null;            // 차량번호
    Integer carqty = null;           // 차량 수량
    Integer carreserveday = null;    // 대여 일수
    String carbegindate = "";        // 대여 시작일
    Integer carins = null;           // 옵션: 자차보험
    Integer carwifi = null;          // 옵션: 와이파이
    Integer carnave = null;          // 옵션: 네비게이션
    Integer carbabyseat = null;      // 옵션: 베이비시트

    if (voObj != null) {
        // Bean getter로 각 속성 값 추출
        try {
            java.lang.reflect.Method m;
            // 차량번호 추출
            m = voObj.getClass().getMethod("getCarno");
            carno = (Integer)m.invoke(voObj);
            // 차량수량 추출
            m = voObj.getClass().getMethod("getCarqty");
            carqty = (Integer)m.invoke(voObj);
            // 대여일수 추출
            m = voObj.getClass().getMethod("getCarreserveday");
            carreserveday = (Integer)m.invoke(voObj);
            // 대여 시작일자 추출
            m = voObj.getClass().getMethod("getCarbegindate");
            carbegindate = (String)m.invoke(voObj);
            // 옵션: 자차보험 추출
            m = voObj.getClass().getMethod("getCarins");
            carins = (Integer)m.invoke(voObj);
            // 옵션: 와이파이 추출
            m = voObj.getClass().getMethod("getCarwifi");
            carwifi = (Integer)m.invoke(voObj);
            // 옵션: 네비게이션 추출
            m = voObj.getClass().getMethod("getCarnave");
            carnave = (Integer)m.invoke(voObj);
            // 옵션: 베이비시트 추출
            m = voObj.getClass().getMethod("getCarbabyseat");
            carbabyseat = (Integer)m.invoke(voObj);
        } catch(Exception e) {
            // 에러 발생시 모든 값 기본값(숫자 0, 문자 "")
            carno = carqty = carreserveday = carins = carwifi = carnave = carbabyseat = 0;
            carbegindate = "";
        }
    }

    // (8) 옵션 선택 되었는지 여부
    boolean hasOption = false;

    // (9) 숫자 1000단위 , 삽입 포맷팅 객체 생성
    java.text.NumberFormat numfmt = java.text.NumberFormat.getInstance();
%>
<%--
 ================================================================================
   CarOrder.jsp (비회원 예약)  -  예약 최종 확인 및 요청 (예약 흐름 3단계)
   [6단계 전면 재작성]
   (기존 화면의 문제 설명 생략)
 ================================================================================
--%>
<div class="container">
    <!-- 단계 안내 영역 -->
    <div class="section-head">
        <span class="section-eyebrow">STEP 3 / 3</span>
        <h2 class="section-heading">예약 확인</h2>
        <p class="section-desc">아래 내용을 확인한 뒤 예약을 완료해 주세요</p>
    </div>
    <form action="<%=contextPath%>/Car/CarOrder.do" method="post">
        <!-- CSRF 토큰 전달 (서버에서 인증용) -->
        <input type="hidden" name="_csrf" value="<%= csrf %>">
        <!-- 예약 정보 hidden 필드 전달 (화면엔 안보이나 서버로 전송해야 함) -->
        <input type="hidden" name="carno" value="<%= (carno != null) ? carno : "" %>" />
        <input type="hidden" name="carqty" value="<%= (carqty != null) ? carqty : "" %>" />
        <input type="hidden" name="carreserveday" value="<%= (carreserveday != null) ? carreserveday : "" %>" />
        <input type="hidden" name="carbegindate" value="<%= carbegindate %>" />
        <input type="hidden" name="carins" value="<%= (carins != null) ? carins : "" %>" />
        <input type="hidden" name="carwifi" value="<%= (carwifi != null) ? carwifi : "" %>" />
        <input type="hidden" name="carnave" value="<%= (carnave != null) ? carnave : "" %>" />
        <input type="hidden" name="carbabyseat" value="<%= (carbabyseat != null) ? carbabyseat : "" %>" />
        <div class="grid-2">
            <!-- 왼쪽 예약 내역 -->
            <div>
                <h3 class="fw-bold mb-4">예약 내역</h3>
                <dl class="detail-list">
                    <!-- 차량명 출력 (XSS 방지로 태그 무효화) -->
                    <div class="detail-row">
                        <dt>차량</dt>
                        <dd>
                            <%
                                // 차량명이 없으면 "선택한 차량"으로 대체, HTML 이스케이프 처리
                                String safeCarname;
                                if (carname == null || carname.trim().length() == 0) {
                                    safeCarname = "선택한 차량";
                                } else {
                                    safeCarname = carname.replaceAll("&","&amp;")
                                                         .replaceAll("<","&lt;")
                                                         .replaceAll(">","&gt;")
                                                         .replaceAll("\"", "&quot;")
                                                         .replaceAll("\'","&#39;");
                                }
                            %>
                            <%= safeCarname %>
                        </dd>
                    </div>
                    <!-- 대여 시작일 표시 -->
                    <div class="detail-row">
                        <dt>대여 시작일</dt>
                        <dd><%= carbegindate %></dd>
                    </div>
                    <!-- 대여 기간 -->
                    <div class="detail-row">
                        <dt>대여 기간</dt>
                        <dd><%= (carreserveday != null ? carreserveday : "") %>일</dd>
                    </div>
                    <!-- 차량 수량 -->
                    <div class="detail-row">
                        <dt>대여 수량</dt>
                        <dd><%= (carqty != null ? carqty : "") %>대</dd>
                    </div>
                    <!-- 옵션 배지로 표시, 없으면 없음 문구 출력 -->
                    <div class="detail-row">
                        <dt>선택 옵션</dt>
                        <dd>
                            <%
                                // 옵션이 하나라도 있으면 hasOption = true
                                hasOption = false;
                                if (carins != null && carins == 1) {
                            %>
                                <span class="badge badge-brand">자차보험</span>
                            <%
                                    hasOption = true;
                                }
                                if (carwifi != null && carwifi == 1) {
                            %>
                                <span class="badge badge-brand">무선 WiFi</span>
                            <%
                                    hasOption = true;
                                }
                                if (carnave != null && carnave == 1) {
                            %>
                                <span class="badge badge-brand">네비게이션</span>
                            <%
                                    hasOption = true;
                                }
                                if (carbabyseat != null && carbabyseat == 1) {
                            %>
                                <span class="badge badge-brand">베이비시트</span>
                            <%
                                    hasOption = true;
                                }
                                if (!hasOption) {
                            %>
                                <span class="text-muted fs-sm">선택한 옵션 없음</span>
                            <%
                                }
                            %>
                        </dd>
                    </div>
                </dl>
            </div>
            <!-- 오른쪽 결제금액 + 예약확인정보 -->
            <div>
                <h3 class="fw-bold mb-4">결제 금액</h3>
                <dl class="detail-list mb-6">
                    <div class="detail-row">
                        <dt>차량 요금</dt>
                        <dd>
                            <%= numfmt.format(totalreserve) %>원
                        </dd>
                    </div>
                    <div class="detail-row">
                        <dt>옵션 요금</dt>
                        <dd>
                            <%= numfmt.format(totaloption) %>원
                        </dd>
                    </div>
                </dl>
                <h3 class="fw-bold mb-4">예약 확인용 정보</h3>
                <div class="form-group">
                    <!-- 연락처 입력란 (필수) -->
                    <label class="form-label" for="memberphone">연락처 <span class="required">*</span></label>
                    <input class="form-control" type="tel" id="memberphone" name="memberphone"
                           placeholder="010-1234-5678" required>
                </div>
                <div class="form-group">
                    <!-- 예약 비밀번호 입력란 (필수) -->
                    <label class="form-label" for="memberpass">예약 비밀번호 <span class="required">*</span></label>
                    <input class="form-control" type="password" id="memberpass" name="memberpass"
                           placeholder="예약 조회·취소에 사용됩니다" required>
                    <!-- 안내 문구 -->
                    <p class="form-hint">
                        &#8226; 이 연락처와 비밀번호로 <strong>예약 조회 · 변경 · 취소</strong>를 합니다.<br>
                        &#8226; 꼭 기억해 주세요. 분실 시 고객센터(02-3456-6574)로 문의해야 합니다.
                    </p>
                </div>
            </div>
        </div>
        <!-- 하단 결제총액/버튼 영역 -->
        <div class="action-bar mt-6">
            <div class="action-total">
                <div class="label">
                    총 결제금액 (
                        <%= (carreserveday != null) ? carreserveday : "" %>일 ·
                        <%= (carqty != null) ? carqty : "" %>대
                    )
                </div>
                <div class="price">
                    <%= numfmt.format(totalreserve + totaloption) %>원
                </div>
            </div>
            <!-- 결제 완료 버튼 -->
            <button type="submit" class="btn btn-primary btn-lg">예약 완료하기</button>
        </div>
        <!-- 차량 목록 돌아가기 버튼 -->
        <div class="flex flex-wrap gap-2 mt-4">
            <a class="btn btn-ghost" href="<%=contextPath%>/Car/CarList.do">&lsaquo; 차량 다시 선택</a>
        </div>
    </form>
</div>
