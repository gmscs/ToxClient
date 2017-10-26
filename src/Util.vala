  namespace Util {
  public static uint8[] hex2bin (string s) {
    uint8[] buf = new uint8[s.length / 2];
    for (int i = 0; i < buf.length; ++i) {
      int b = 0;
      s.substring (2*i, 2).scanf ("%02x", ref b);
      buf[i] = (uint8)b;
    }
    return buf;
  }

  public static string bin2hex (uint8[] bin)
  requires (bin.length != 0) {
    StringBuilder b = new StringBuilder ();
    for (int i = 0; i < bin.length; ++i) {
      b.append ("%02X".printf (bin[i]));
    }
    return b.str;
  }

  public inline static string arr2str (uint8[] array) {
    uint8[] str = new uint8[array.length + 1];
    Memory.copy (str, array, sizeof(uint8) * array.length);
    str[array.length] = '\0';
    string result = (string) str;
    assert (result.validate ());
    return result;
  }

  public static string escape_html (string text) {
    return Markup.escape_text (text);
  }

  
  public static string render_litemd (string text) { //TODO: Christ what is this
    var md = text;

    var emojis = md.replace (":+1:", "👍")
                 .replace (":-1:", "👎")
                 .replace (":@", "😠")
                 .replace (">:(", "😠")
                 .replace (":$", "😊")
                 .replace ("<3", "💙")
                 .replace (":3", "🐱")
                 .replace (":\\", "😕")
                 .replace (":'(", "😢")
                 .replace (":-'(", "😢")
                 .replace (":o", "😵")
                 .replace (":O", "😵")
                 .replace (":(", "😦")
                 .replace (":-(", "😦")
                 .replace (":-[", "😦")
                 .replace (":[", "😦")
                 .replace ("xD", "😁")
                 .replace ("XD", "😁")
                 .replace ("0:)", "😇")
                 .replace (":)", "😄")
                 .replace (":D", "😆")
                 .replace (":-D", "😆")
                 .replace (":|", "😐")
                 .replace (":-|", "😐")
                 .replace (":p", "😛")
                 .replace (":-p", "😛")
                 .replace (":P", "😛")
                 .replace (":-P", "😛")
                 .replace ("8)", "😎")
                 .replace ("8-)", "😎");
    
    // Markdown.
    var bold = /\B\*\*([^\*\*]*)\*\*\B/.replace (emojis, -1, 0, "<b>\\1</b>");
    var italic = /\B\/\/([^\/\/]*)\/\/\B/.replace(bold, -1, 0, "<i>\\1</i>");
    var underlined = /\b__([^__]*)__\b/.replace(italic, -1, 0, "<u>\\1</u>");
    var striked = /\B~~([^~~]*)~~\B/.replace(underlined, -1, 0, "<s>\\1</s>");
    var inline_code = /\B`([^`]*)`\B/.replace(striked, -1, 0, "<span face=\"monospace\" size=\"smaller\">\\1</span>");
    var uri = /(\w+:\/?\/?[^\s]+)/.replace (inline_code, -1, 0, "<span color=\"#2a92c6\"><a href=\"\\1\">\\1</a></span>");

    var message = uri;
    debug (@"Message: $message");

    return message;
  }
  
  public static string add_markup (string text) {
    
    var sb = new StringBuilder ();
    foreach (string line in text.split ("\n")) { // multiple lines
      string xfmd = escape_html (line);
      if (line[0] == '>') { // greentext
        xfmd = @"<span color=\"#2ecc71\">$xfmd</span>";
      }
      sb.append (xfmd);
      sb.append_c ('\n');
    }
    sb.truncate (sb.len-1);
  
    var md = Util.render_litemd (sb.str);
    return md;
  }
  
  public static string status_to_icon (Tox.UserStatus status, int messagesCount = 0) {
    string icon = "";

    switch (status) {
      case Tox.UserStatus.BLOCKED:
        icon = (messagesCount > 0) ? "user-invisible" : "user-invisible";
        break;
      case Tox.UserStatus.ONLINE:
        icon = (messagesCount > 0) ? "mail-mark-unread" : "user-available";
        break;
      case Tox.UserStatus.AWAY:
        icon = (messagesCount > 0) ? "mail-mark-unread" : "user-away";
        break;
      case Tox.UserStatus.BUSY:
        icon = (messagesCount > 0) ? "mail-mark-unread" : "user-busy";
        break;
      case Tox.UserStatus.OFFLINE:
      default:
        icon = (messagesCount > 0) ? "mail-mark-unread" : "user-offline";
        break;
    }

    return icon;
  }
  
  public static string status_to_string (Tox.UserStatus status) {
    string str = "";

    switch (status) {
      case Tox.UserStatus.BLOCKED:
        str = "Blocked";
        break;
      case Tox.UserStatus.ONLINE:
        str = "Available";
        break;
      case Tox.UserStatus.AWAY:
        str = "Away";
        break;
      case Tox.UserStatus.BUSY:
        str = "Busy";
        break;
      case Tox.UserStatus.OFFLINE:
      default:
        str = "Offline";
        break;
    }

    return str;
  }
}
