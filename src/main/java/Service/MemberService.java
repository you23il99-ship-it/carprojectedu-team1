// 이 파일이 속한 폴더(패키지) 이름. 실제 폴더 경로 Service 와 반드시 같아야 한다
package Service;   // 이 파일이 속한 패키지(=폴더) 이름. 실제 폴더 구조와 반드시 같아야 한다

// HttpServletRequest 를 가져온다 — 브라우저가 보낸 요청(파라미터·세션)을 담은 객체를 쓰기 위해
import javax.servlet.http.HttpServletRequest;   // 브라우저가 보낸 요청(주소·파라미터·세션)이 담긴 객체
// HttpSession 를 가져온다 — 로그인 정보를 서버에 기억시키기 위해
import javax.servlet.http.HttpSession;   // 로그인 정보처럼 사용자별로 서버에 보관하는 저장소
// Dao 안의 MemberDAO 를 이 파일에서 쓰겠다는 선언
import Dao.MemberDAO;   // DB 에 직접 SQL 을 보내는 DAO 클래스
// Vo 안의 MemberVO 를 이 파일에서 쓰겠다는 선언
import Vo.MemberVO;   // 값을 담아 나르는 상자(VO) 클래스
// util 안의 DBCPUtil 를 이 파일에서 쓰겠다는 선언
import util.DBCPUtil;   // 여러 곳에서 함께 쓰는 도우미 클래스
/**
 * MemberService  부장 클래스
 *
 * ✔ 하는 일:
 * - Controller(사장)의 지시를 받아
 * - 업무 규칙(검증, 비밀번호 처리, 권한 판단)을 적용하고
 * - DAO(사원)에게 SQL 실행을 시킨다
 *
 * ================================================================================
 * [3단계에서 바뀐 점 - 트랜잭션 경계를 Service가 소유한다]
 *
 *   (기존)
 *       memberDao.insertMember(vo);
 *       -> DAO가 스스로 연결을 열고 SQL을 실행하고 닫았다.
 *          여러 SQL을 하나의 작업으로 묶을 방법이 없었다.
 *
 *   (지금)
 *       DBCPUtil.execute(con -> memberDao.insertMember(con, vo));
 *       -> Service가 연결을 열어 DAO에 넘긴다.
 *          한 연결로 여러 DAO 메소드를 호출하면 그것이 하나의 트랜잭션이 된다.
 *
 *   왜 Service가 관리하는가?
 *     "어디까지가 하나의 작업 단위인가"는 업무 규칙이다.
 *     DAO는 SQL 하나만 알고, 묶는 판단은 업무를 아는 계층이 해야 한다.
 *
 *   DBCPUtil.query(...)   : 조회 전용 (커밋할 것이 없음)
 *   DBCPUtil.execute(...) : 데이터 변경 (성공하면 commit, 실패하면 rollback)
 * ================================================================================
 */
public class MemberService {
	//MemberDAO 사원 객체의 주소번지를 저장할 참조변수 선언
	private final MemberDAO memberDao;
	//생성자 - 위 memberDao 참조변수에  new MemberDAO()객체를 만들어 주소번지 저장하는 역할
	public MemberService() {
		// memberDao 에 새 MemberDAO 을 만들어 담는다
		this.memberDao = new MemberDAO();   // DAO 를 하나 만들어 계속 재사용한다
	}
			// ◀◀ 붙여넣는 자리 1 ◀◀ — 기능 장에서 "자리 1" 라고 알려주는 조각을 이 줄 아래에
	/**
	 * request 에 들어있는 회원정보를 MemberVO 객체로 만들어주는 메소드
	 *
	 * ✔ 왜 따로 만들었을까?
	 * - 코드가 깔끔해진다.
	 * - 재사용이 가능하다.
	 */
	private MemberVO buildMemberFromRequest(HttpServletRequest request) {
		//1. 사용자가 가입을 위해 입력해서 요청한 값들을 request객체에서 꺼낸다.
		String id     = trim(request.getParameter("id"));
		// 화면에서 넘어온 비밀번호 값을 꺼내 pass 에 담는다. 없으면 null 이 들어온다
		String pass   = request.getParameter("pass");   // 비밀번호는 공백도 뜻이 있을 수 있어 trim 하지 않고 그대로 받는다
		// 화면(form·링크)에서 보낸 이름 값을 꺼낸다
		String name   = trim(request.getParameter("name"));   // 이름 (앞뒤 공백 제거)
		// 화면(form·링크)에서 보낸 gender 값을 꺼낸다
		String gender = trim(request.getParameter("gender"));   // 성별
		// 화면(form·링크)에서 보낸 이메일 값을 꺼낸다
		String email  = trim(request.getParameter("email"));   // 이메일
		// 화면(form·링크)에서 보낸 전화번호 값을 꺼낸다
		String tel    = trim(request.getParameter("tel"));   // 전화번호
		// 화면(form·링크)에서 보낸 hp 값을 꺼낸다
		String hp     = trim(request.getParameter("hp"));   // 휴대폰번호
		//나이는 숫자이므로 변환한다. 잘못된 값이 와도 예외로 죽지 않게 0으로 둔다.
		int age = 0;
		// 오류가 날 수 있는 구간의 시작. 실패해도 프로그램이 멈추지 않게 감싼다
		try {
			// 화면(form·링크)에서 보낸 age 값을 꺼낸다
			age = Integer.parseInt(trim(request.getParameter("age")));
		// 앞 구간에서 Exception 오류가 나면 여기로 온다
		} catch (Exception e) {
			// age 에 계산한 값을 담는다
			age = 0;   // 숫자가 아닌 값이 들어와도 서버가 죽지 않게 0 으로 둔다
		}
		/*
		 주소는 여러 칸으로 나뉘어 오므로 하나로 합친다.
		 [기존 버그] String.join 에 null이 섞이면 "null" 이라는 글자가 그대로 붙는다.
		            주소를 일부만 입력하면 "서울시null강남구null" 처럼 저장됐다.
		            그래서 null을 빈 문자열로 바꿔 합친다.
		*/
		String address = trim(request.getParameter("address1"))
					   + trim(request.getParameter("address2"))
					   + trim(request.getParameter("address3"))
					   + trim(request.getParameter("address4"))
					   + trim(request.getParameter("address5"));
		/*
		 [보안] 비밀번호를 그대로 담지 않고 PBKDF2 해시로 바꿔 담는다.
		   기존에는 사용자가 입력한 "1234"가 그대로 DB에 저장됐다.
		   DB가 유출되면 전 회원의 비밀번호가 그대로 노출되고,
		   사람들은 여러 사이트에 같은 비밀번호를 쓰기 때문에 피해가 여기서 끝나지 않는다.
		   해시는 되돌릴 수 없으므로(일방향) 유출돼도 원래 비밀번호를 알 수 없다.
		   "비밀번호를 저장하지 않고, 맞는지만 확인할 수 있게 저장한다"가 핵심이다.
		*/
		if (pass == null || pass.trim().isEmpty()) {
			// exception 를 던져 여기서 중단한다. 위쪽 공통 처리기가 받아 알맞은 오류 화면을 보여준다
			throw new exception.InvalidInputException("비밀번호를 입력해주세요");
		}
		String encodedPass = (pass.trim());   // 앞뒤 공백을 없앤 비밀번호. (교육판이라 해시를 걷어내고 평문 그대로 쓴다)
		//2. 가입할 데이터들을 모두 MemberVO객체를 생성하여 변수에 저장 후 반환
		return new MemberVO(id, encodedPass, name, age, gender, address, email, tel, hp);
	}
	/** null 을 빈 문자열로 바꾸고 앞뒤 공백을 제거한다 */
	private String trim(String value) {
		// return( ) 를 실행한다 — 넘기는 값이 다음 줄로 이어진다
		return (value == null) ? "" : value.trim();   // 값이 없으면 빈 문자열로, 있으면 앞뒤 공백을 없앤다
	}
	public boolean idCheck(String id) throws Exception {
	    return DBCPUtil.query(con -> memberDao.overlappedId(con, id));
	}
			// ◀◀ 붙여넣는 자리 2 ◀◀ — 기능 장에서 "자리 2" 라고 알려주는 조각을 이 줄 아래에
	
}