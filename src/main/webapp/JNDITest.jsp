<%-- 이 화면에서 DataSource 클래스를 쓰겠다는 선언. 아래 자바 코드 구간에서 사용한다 --%>
<%@page import="javax.sql.DataSource"%>
<%-- 이 화면에서 InitialContext 클래스를 쓰겠다는 선언. 아래 자바 코드 구간에서 사용한다 --%>
<%@page import="javax.naming.InitialContext"%>
<%-- 이 화면에서 Context 클래스를 쓰겠다는 선언. 아래 자바 코드 구간에서 사용한다 --%>
<%@page import="javax.naming.Context"%>
<%-- 이 화면에서 Connection 클래스를 쓰겠다는 선언. 아래 자바 코드 구간에서 사용한다 --%>
<%@page import="java.sql.Connection"%>
<%-- 이 페이지의 글자 인코딩을 UTF-8 로 정한다. 빠뜨리면 한글이 깨진다 --%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%-- 이 문서가 HTML5 라는 선언. 항상 첫 줄에 온다 --%>
<!DOCTYPE html>
<%-- 문서 전체 시작 --%>
<html>
<%-- 화면에 안 보이는 설정 구역 --%>
<head>
<%-- 글자 인코딩 설정. 한글이 깨지지 않게 한다 --%>
<meta charset="UTF-8">
<%-- 브라우저 탭에 표시되는 제목 --%>
<title>Insert title here</title>
</head>
<%-- 실제로 보이는 내용 구역 --%>
<body>
	<%-- 가장 큰 제목 --%>
	<h1>DB연동 테스트</h1>
	<%
		// conn — 비어 있음(null) 으로 둔다
		Connection conn = null;
		// 오류가 날 수 있는 구간의 시작. 실패해도 프로그램이 멈추지 않게 감싼다
		try{
			// InitialContext 그릇을 새로 하나 만들어 init 라는 이름으로 잡아 둔다
			Context init = new InitialContext();
			//커넥션풀 얻기 
			DataSource ds = (DataSource)init.lookup("java:comp/env/jdbc/jspbeginner");
			//커넥션풀에서 커넥션 객체 빌려 오기
			conn = ds.getConnection();
			// 조건을 확인해 맞을 때만 아래를 실행한다
			if(conn != null) out.print("DB와의 연결 성공");
		// 앞 구간에서 Exception 오류가 나면 여기로 온다
		}catch(Exception err){
			// err 의 printStackTrace( ) 를 실행한다
			err.printStackTrace();
		}
	%>
</body>
</html>