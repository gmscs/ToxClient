[GtkTemplate (ui="/chat/tox/ricin/ui/chat-view.ui")]
class Ricin.ChatView : Gtk.Box {
  [GtkChild] Gtk.ScrolledWindow scroll_messages;
  [GtkChild] Gtk.ListBox messages_list;
  [GtkChild] public Gtk.Entry entry;
  [GtkChild] Gtk.Button send_file;
  [GtkChild] Gtk.Revealer friend_typing;

  public Tox.Friend fr;
  private weak Tox.Tox handle;
  private weak Gtk.Stack stack;
  private string view_name;
  private ulong[] handlers = {};
  
  private Tox.UserStatus last_status;

  private enum MessageRowType {
    Normal,
    Action,
    System,
    InlineFile,
    GtkListBoxRow
  }

  private string time () {
    return new DateTime.now_local ().format ("%I:%M:%S %p");
  }

  public ChatView (Tox.Tox handle, Tox.Friend fr, Gtk.Stack stack, string view_name) {
    this.handle = handle;
    this.fr = fr;
    this.stack = stack;
    this.view_name = view_name;
    this.name = fr.name;

    handlers += fr.friend_info.connect ((message) => {
      messages_list.add (new SystemMessageListRow (message));
    });

    handlers += handle.global_info.connect ((message) => {
      messages_list.add (new SystemMessageListRow (message));
    });

    handlers += fr.message.connect (message => {
      var main_window = this.get_toplevel () as MainWindow;
      var visible_child = this.stack.get_visible_child_name ();
      if (visible_child != this.view_name || !main_window.is_active) {
        var avatar_path = Tox.profile_dir () + "avatars/" + this.fr.pubkey + ".png";
        if (FileUtils.test (avatar_path, FileTest.EXISTS)) {
          var pixbuf = new Gdk.Pixbuf.from_file_at_scale (avatar_path, 46, 46, true);
          Notification.notify (fr.name, message, 5000, pixbuf);
        } else {
          Notification.notify (fr.name, message, 5000);
        }
      }

      messages_list.add (new MessageListRow (fr.name, Util.add_markup (message), time ()));
    });

    handlers += fr.action.connect (message => {
      var main_window = this.get_toplevel () as MainWindow;
      var visible_child = this.stack.get_visible_child_name ();
      if (visible_child != this.view_name || !main_window.is_active) {
        var avatar_path = Tox.profile_dir () + "avatars/" + this.fr.pubkey + ".png";
        if (FileUtils.test (avatar_path, FileTest.EXISTS)) {
          var pixbuf = new Gdk.Pixbuf.from_file_at_scale (avatar_path, 46, 46, true);
          Notification.notify (fr.name, message, 5000, pixbuf);
        } else {
          Notification.notify (fr.name, message, 5000);
        }
      }

      string message_escaped = @"$(fr.name) $message";
      messages_list.add (new SystemMessageListRow (message_escaped));
    });

    handlers += fr.file_transfer.connect ((name, size, id) => {

        string filename = name;
        int i = 0;

        while (FileUtils.test (filename, FileTest.EXISTS)) { //TODO: This is gonna break when I fix file choose location
            filename = @"($(++i))$name";
        }
        var path = @"/tmp/$name";

        var file_row = new InlineFileMessageListRow (fr, id, fr.name, path, size, filename, time ());
        file_row.accept_file.connect ((response, file_id) => {
          fr.reply_file_transfer (response, file_id);
        });
        messages_list.add (file_row);
    });
    
    this.fr.notify["status"].connect ((obj, prop) => {
      if (this.last_status != this.fr.status) {
        var status_str = Util.status_to_string (this.fr.status);
        messages_list.add (new SystemMessageListRow (fr.name + " is now " + status_str));
        this.last_status = this.fr.status;
      }
    });

    fr.bind_property ("connected", entry, "sensitive", BindingFlags.DEFAULT);
    fr.bind_property ("connected", send_file, "sensitive", BindingFlags.DEFAULT);
    
    this.entry.changed.connect (() => {
      var is_typing = (this.entry.text.strip () != "");
      this.fr.send_typing (is_typing);
    });
    this.entry.backspace.connect (() => {
      var is_typing = (this.entry.text.strip () != "");
      this.fr.send_typing (is_typing);
    });

    this.fr.notify["typing"].connect ((obj, prop) => {
      this.friend_typing.reveal_child = this.fr.typing;
      if (this.fr.typing == false) {
        this.scroll_to_bottom ();
      }
    });
  }

  ~ChatView () {
    foreach (ulong h in handlers) {
      fr.disconnect (h);
    }
  }

  [GtkCallback]
  private void send_message () {
    var user = this.handle.username;
    string markup;

    var message = this.entry.get_text ();
    if (message.strip () == "") {
      return;
    }

    if (message.has_prefix ("/me ")) {
      var escaped = Util.escape_html (message);
      var action = escaped.substring (4);
      markup = @"$user $action";
      messages_list.add (new SystemMessageListRow (markup));
      fr.send_action (action);
    } else {
      markup = Util.add_markup (message);
      messages_list.add (new MessageListRow (user, markup, time ()));
      fr.send_message (message);
    }

    // clear the entry
    this.entry.text = "";
  }

  [GtkCallback]
  private void choose_file_to_send () {
    var chooser = new Gtk.FileChooserDialog ("Choose a File", //NOTE 
        get_toplevel () as Gtk.Window,
        Gtk.FileChooserAction.OPEN,
        "_Cancel", Gtk.ResponseType.CANCEL,
        "_Open", Gtk.ResponseType.ACCEPT);
    if (chooser.run () == Gtk.ResponseType.ACCEPT) {
      var filename = chooser.get_filename ();
      File file = File.new_for_path (filename);
      FileInfo info = file.query_info ("standard::*", 0);
      var file_id = fr.send_file (filename);
      var file_content_type = ContentType.guess (filename, null, null);
      var size = info.get_size ();

        var file_row = new InlineFileMessageListRow (fr, file_id, this.handle.username, filename, size, filename, time ());
        messages_list.add (file_row);
    }
    chooser.close ();
  }

  [GtkCallback]
  private void scroll_to_bottom () {
    var adjustment = this.scroll_messages.get_vadjustment ();
    adjustment.set_value (adjustment.get_upper () - adjustment.get_page_size ());
  }
}
