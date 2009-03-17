<%@ page contentType="text/html; charset=utf-8"%>
<%@ page import="java.io.IOException,java.net.URLEncoder,java.sql.*,java.util.Date"   buffer="60kb" %>
<%@ page import="java.util.Map"%>
<%@ page import="com.danga.MemCached.MemCachedClient" %>
<%@ page import="ru.org.linux.site.*" %>
<%@ page import="ru.org.linux.util.BadImageException" %>
<%@ page import="ru.org.linux.util.HTMLFormatter" %>
<%@ page import="ru.org.linux.util.ImageInfo" %>
<% Template tmpl = Template.getTemplate(request); %>
<jsp:include page="WEB-INF/jsp/head.jsp"/>

<% 
	String nick=request.getParameter("nick");
	if (nick==null) {
          throw new MissingParameterException("nick");
        }

	Connection db = null;

	try {
          db = LorDataSource.getConnection();

          User user = User.getUser(db, nick);

	  int offset = 0;
	  
	  if (request.getParameter("offset") != null) {
		offset = Integer.parseInt(request.getParameter("offset"));
		if (offset < 0) offset = 0;
	  }

	/* first page should be treated specially */
	boolean firstPage = ! (offset > 0);
	  
	int topics = 50;
	int count = offset + topics;

	/* define timestamps for caching */
	long time = System.currentTimeMillis();
	int delay = firstPage ? 90 : 60*60;

	String howmany = firstPage ? ("" + topics) : (count + "-" + offset);
	String title = "Последние " + howmany + 
		" ответов на комментарии пользователя " + nick;
	response.setDateHeader("Expires", time + 1000 * delay);

	out.print ("<title>"+title+"</title>");
%>
<jsp:include page="WEB-INF/jsp/header.jsp"/>
<%
	out.print("<h1>"+title+"</h1>");
%>

<div class=forum>
<table width="100%" class="message-table">
<thead>
<tr><th>Раздел</th><th>Группа</th><th>Заглавие темы</th><th>Автор</th><th>Дата</th></tr>
<tbody>
<%

	MemCachedClient mcc=MemCachedSettings.getClient();
	String cachedOutput = MemCachedSettings.getId(
		 "show-replies?id="+URLEncoder.encode(nick)+"&offset="+offset
	);

  	String res;
	res = (String) mcc.get(cachedOutput);
	if (res==null) {
		res = MessageTable.showReplies (db, user, offset, topics);
		mcc.add(cachedOutput, res, new Date (time + 1000L * delay));
	}
 
  	out.print(res);
%>
</tbody>
<tfoot>
  <tr><td colspan=5><p>
<%
  out.print("<div style=\"float: left\">");
  if (firstPage || (offset - topics)<0) {
	out.print("");
  } else {
	out.print("<a rel=prev rev=next href=\"show-replies.jsp?nick=" + nick + "&amp;offset=" + (offset - topics) + "\">← назад</a>");
  }
  out.print("</div>");
  
  out.print("<div style=\"float: right\">");
  if (res!=null && !"".equals(res)) {
	out.print("<a rel=next rev=prev href=\"show-replies.jsp?nick=" + nick + "&amp;offset=" + (offset + topics) + "\">вперед →</a>");
  } else {
	out.print("<a rel=next rev=prev href=\"show-replies.jsp?nick=" + nick + "&amp;offset=0\">первая →</a>");    
  }
  out.print("</div>");
%>
  </td></tr>
</tfoor>
</table>
</div>

<%
  } finally {
    if (db!=null) {
      db.close();
    }
  }
%>
<jsp:include page="WEB-INF/jsp/footer.jsp"/>
