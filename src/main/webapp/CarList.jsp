<%-- 목록을 하나씩 꺼내며 아래 내용을 반복해 그린다 --%>
				<c:forEach var="vo" items="${requestScope.v}">
					<%-- 다른 화면으로 넘어가는 링크 --%>
					<a class="car-card" href="${contextPath}/Car/CarInfo.do?carno=${vo.carno}">