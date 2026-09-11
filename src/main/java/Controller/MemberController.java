// 이 파일이 속한 폴더(패키지) 이름. 실제 폴더 경로 Controller 와 반드시 같아야 한다
package Controller;   // 이 파일이 속한 패키지(=폴더) 이름. 실제 폴더 구조와 반드시 같아야 한다
// IOException 를 가져온다 — 입출력 중 생기는 오류를 받기 위해
import java.io.IOException;   // 파일/네트워크 입출력이 실패했을 때의 예외
// java.io 안의 PrintWriter 를 이 파일에서 쓰겠다는 선언
import java.io.PrintWriter;   // 응답 화면에 글자를 직접 찍어 보낼 때 쓰는 도구 (AJAX 응답에 사용)
// javax.servlet 안의 ServletConfig 를 이 파일에서 쓰겠다는 선언
import javax.servlet.ServletConfig;   // 서블릿의 설정값을 읽는 객체
// javax.servlet 안의 ServletException 를 이 파일에서 쓰겠다는 선언
import javax.servlet.ServletException;   // 서블릿이 처리 중 실패했을 때의 예외
// javax.servlet.annotation 안의 WebServlet 를 이 파일에서 쓰겠다는 선언
import javax.servlet.annotation.WebServlet;   // 이 서블릿이 어떤 주소의 요청을 받을지 정하는 표시 (아래 클래스 위에 붙어 있다)
// HttpServletRequest 를 가져온다 — 브라우저가 보낸 요청(파라미터·세션)을 담은 객체를 쓰기 위해
import javax.servlet.http.HttpServletRequest;   // 브라우저가 보낸 요청(주소·파라미터·세션)이 담긴 객체
// HttpServletResponse 를 가져온다 — 브라우저로 보낼 응답을 다루기 위해
import javax.servlet.http.HttpServletResponse;   // 브라우저에게 돌려줄 응답을 담는 객체
// Service 안의 MemberService 를 이 파일에서 쓰겠다는 선언
import Service.MemberService;   // 업무 규칙을 담당하는 Service 클래스
// HttpSession 를 가져온다 — 로그인 정보를 서버에 기억시키기 위해
import javax.servlet.http.HttpSession;   // 로그인 정보처럼 사용자별로 서버에 보관하는 저장소
// Vo 안의 MemberVO 를 이 파일에서 쓰겠다는 선언
import Vo.MemberVO;   // 값을 담아 나르는 상자(VO) 클래스
// util 안의 KakaoAuth 를 이 파일에서 쓰겠다는 선언
import util.KakaoAuth;   // 여러 곳에서 함께 쓰는 도우미 클래스
//MVC 디자인 패턴 개발 방법 중에서   C의 역할 을 하는 회원관련 처리  서블릿 
@WebServlet("/member/*")  
// MemberController 클래스를 만든다. BaseController 를 상속받아 공통 기능(요청 분기·오류 처리)을 그대로 물려받는다
public class MemberController extends BaseController {
	//직렬화 버전 번호 (HttpServlet이 Serializable을 구현하므로 경고 방지용으로 선언)
	private static final long serialVersionUID = 1L;
	//MemberService 부장 객체의 주소번지를 저장시킬 참조변수 선언
	//(transient : 서블릿 직렬화 대상에서 제외 - init()에서 다시 생성되므로 저장할 필요 없음)
	transient MemberService memberService;
	// 부모 클래스에 이미 있는 메서드를 여기서 다시 만든다는 표시. 이름을 잘못 쓰면 컴파일 오류로 잡아준다
	@Override   // 부모(HttpServlet)의 init 을 덮어쓴다는 표시
	// init( ) 메서드 — 1개 값을 받아 돌려주는 값 없이 일만 한다
	public void init(ServletConfig config) throws ServletException {
		//init메소드가 처음 호출되면!~  MemberService객체를 생성해서 주소번지  위 memberService참조변수에 저장
		memberService = new MemberService();
	}
	protected void doHandle(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {   // 실제 처리를 담당하는 메소드. 아래 process() 가 이걸 부른다
		//재료 준비 
		request.setCharacterEncoding("UTF-8");
		// 응답이 어떤 형식(HTML·JSON 등)인지 브라우저에게 알려준다
		response.setContentType("text/html;charset=UTF-8");   // 응답이 HTML 이고 한글은 UTF-8 이라고 브라우저에 알린다
		// 응답의 한글이 깨지지 않게 UTF-8 로 보낸다
		response.setCharacterEncoding("UTF-8");   // 응답 글자를 UTF-8 로 내보낸다 (안 하면 한글이 깨진다)
		// 브라우저로 글자를 내보낼 출력 통로를 얻는다
		PrintWriter out = response.getWriter();   // 응답에 글자를 쓸 수 있는 붓을 얻는다
		String nextPage = null;   //2단계 요청한 주소에 따라 포워딩 또는 보여줄 VIEW주소 경로가 저장될 변수 선언 (재료)
		String center = null;     //2단계 요청한 주소에 따라 보여줄 중앙 VIEW주소 경로가 저장될 변수 선언(재료)
		
		String action = request.getPathInfo();
		// 서버 콘솔에 찍어 확인용으로 남긴다
		System.out.println("클라이언트가 요청한 2단계 요청 주소  : " + action);   // 어떤 주소가 들어왔는지 이클립스 콘솔에 찍는다. 화면이 안 뜰 때 여기부터 확인한다
		/*
		 [추가] 2단계 주소가 없는 요청 차단
		   /CarProject/member  처럼 2단계 주소 없이 요청하면 getPathInfo()가 null을 반환한다.
		   그 상태로 switch(null) 을 실행하면 NullPointerException 500 에러가 났다.
		   "없는 주소"는 서버 고장(500)이 아니라 404로 답해야 한다.
		*/
		if(action == null) {
			// response 의 sendError( ) 를 실행한다
			response.sendError(HttpServletResponse.SC_NOT_FOUND);
			return;   // 여기서 메소드를 끝낸다. 아래 코드를 실행하면 안 되기 때문이다
		}
		// 값에 따라 갈래를 나눈다
		switch(action) {

	    case "/join.me":
	        center = "members/join.jsp";
	        nextPage = "/CarMain.jsp";
	        request.setAttribute("center", center);
	        break;

	    case "/joinIdCheck.me":
	        String id = request.getParameter("id");

	        boolean overlapped = false;
			try {
				overlapped = memberService.idCheck(id);
			} catch (Exception e) {
				e.printStackTrace();
			}

	        if (overlapped) {
	            out.print("not_usable");
	        } else {
	            out.print("usable");
	        }

	        return;

	    default:
	        break;
	}

		if(nextPage == null) {
		    response.sendError(HttpServletResponse.SC_NOT_FOUND);
		    return;
		}

		
		//디스패처 방식으로 /CarMain.jsp 포워딩(재요청)
		request.getRequestDispatcher(nextPage).forward(request, response);
		
	}//doHandle( ) 메서드 끝
	//===========================================================
	// 요청 진입점 : BaseController 가 GET/POST 를 한곳으로 모아준다
	//===========================================================
	/*
	  [왜 doGet/doPost 를 직접 만들지 않는가]
	    공통 예외 처리를 BaseController 한곳에 모으기 위해서다.
	    이 메소드는 BaseController 와 기존 doHandle 을 이어주는 다리다.
	 */
	@Override
	// process( ) 메서드 — 3개 값을 받아 돌려주는 값 없이 일만 한다
	protected void process(String action, HttpServletRequest request, HttpServletResponse response) throws Exception {
		// doHandle( ) 를 실행한다 — 넘기는 값이 다음 줄로 이어진다
		doHandle(request, response);   // 실제 처리는 위에 있는 doHandle 이 한다
	}
	/* 로그인해야만 쓸 수 있는 주소 (예전 web.xml AuthFilter 대신) */
	@Override
	// requiresLogin( ) 메서드 — 1개 값을 받아 boolean 를 돌려준다
	protected boolean requiresLogin(String action) {
		return action.equals("/memberUpdate.me")   // 세 주소만 로그인이 필요하다. 나머지(가입·로그인 화면 등)는 누구나 쓸 수 있어야 한다
			|| action.equals("/memberUpdatePro.me")
			|| action.equals("/memberDelete.me");
	}
}