[GtkTemplate (ui="/chat/tox/ricin/ui/main-window.ui")]
public class Ricin.MainWindow : Gtk.ApplicationWindow {
  // Header
  [GtkChild] Gtk.Paned paned_header;
  [GtkChild] Gtk.Paned paned_main;
  [GtkChild] Gtk.HeaderBar headerbar_right;
  [GtkChild] Gtk.Button button_call;
  [GtkChild] Gtk.Button button_video_chat;

  // Profile button
  [GtkChild] Gtk.MenuButton button_show_profile;
  [GtkChild] Gtk.Image profile_button_avatar;
  [GtkChild] Gtk.Label profile_button_username;
  [GtkChild] Gtk.Label profile_button_status;
  [GtkChild] Gtk.Image profile_button_userstatus;

  // Profile popover
  [GtkChild] Gtk.Widget profile_popover_content;
  [GtkChild] Gtk.Image avatar_image;
  [GtkChild] Gtk.Entry entry_name;
  [GtkChild] Gtk.Entry entry_status;
  [GtkChild] Gtk.Label label_tox_id;

  // Friend list
  [GtkChild] Gtk.ListBox friendlist;
  [GtkChild] Gtk.ToggleButton toggle_search;
  [GtkChild] Gtk.SearchBar friend_search_bar;
  [GtkChild] Gtk.SearchEntry friend_search;

  // Main Content pane
  [GtkChild] public Gtk.Stack chat_stack;

  // Add friend popover
  [GtkChild] Gtk.Widget add_friend_popover_content;
  [GtkChild] Gtk.MenuButton button_add_friend_show;
  [GtkChild] Gtk.Entry entry_friend_id;
  [GtkChild] Gtk.TextView entry_friend_message;
  [GtkChild] Gtk.Label label_add_error;

  // System notify
  [GtkChild] public Gtk.Revealer revealer_system_notify;
  [GtkChild] public Gtk.Label label_system_notify;

  private ListStore friends = new ListStore (typeof (Tox.Friend));

  public Tox.Tox tox;
  public string focused_view;

  public signal void notify_message (string message, int timeout = 5000);

  private string avatar_path () {
    return Tox.profile_dir () + "avatars/" + this.tox.pubkey + ".png";
  }

  public void remove_friend (Tox.Friend fr) {
    var friend = (this.friends.get_object (fr.position) as Tox.Friend);
    var dialog = new Gtk.MessageDialog (this,
                                        Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.NONE,
                                        @"Are you sure you want to delete \"$(friend.name)\"?");
    dialog.secondary_text = @"This will remove \"$(friend.name)\" and the chat history with it forever.";
    dialog.add_buttons ("Yes", Gtk.ResponseType.ACCEPT, "No", Gtk.ResponseType.REJECT);
    dialog.response.connect (response => {
      if (response == Gtk.ResponseType.ACCEPT) {
        bool result = friend.delete ();
        if (result) {
          this.friends.remove (friend.position);
          this.tox.save_data ();
        }
      }

      dialog.destroy ();
    });

    dialog.show ();
  }

  public MainWindow (Gtk.Application app, string profile) {
    Object (application: app, show_menubar: false);

    var opts = Tox.Options.create ();
    opts.ipv6_enabled = true;
    opts.udp_enabled = true;

    try {
      this.tox = new Tox.Tox (opts, profile);
    } catch (Tox.ErrNew error) {
      warning ("Tox init failed: %s", error.message);
      this.destroy ();
      var error_dialog = new Gtk.MessageDialog (null,
          Gtk.DialogFlags.MODAL,
          Gtk.MessageType.WARNING,
          Gtk.ButtonsType.OK,
          "Can't load the profile");
      error_dialog.secondary_use_markup = true;
      error_dialog.format_secondary_markup (@"<span color=\"#e74c3c\">$(error.message)</span>");
      error_dialog.response.connect (resp => error_dialog.destroy ()); // if we don't use a signal the profile chooser closes
      error_dialog.show ();
      return;
    }

    paned_header.bind_property ("position", paned_main, "position", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
    (bind, src, ref target) => {
      target = src;
      var header = bind.source as Gtk.Paned;
      var main = bind.target as Gtk.Paned;
      if (header.position < main.min_position) {
        header.position = main.min_position;
      } else if (main.max_position < header.position) {
        header.position = main.max_position;
      }
      return true;
    });

    // window title = "headebar title - Ricin"
    headerbar_right.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE, (bind, src, ref target) => {
      target = @"$(src.get_string ()) \u2015 Ricin";
      return true;
    });

    // update headerbar title
    this.chat_stack.notify["visible-child"].connect ((obj, prop) => {
      var widget = this.chat_stack.visible_child;
      button_call.visible = false;
      button_video_chat.visible = false;
      if (widget != null) {
        headerbar_right.title = widget.name;

        if (widget is ChatView) {
          button_call.visible = true;
          button_video_chat.visible = true;
        }
      }
    });

    // Display the settings window while there is no friends online.
    var settings = new SettingsView (this.tox);
    this.chat_stack.add_named (settings, settings.name);

    var path = avatar_path ();
    if (FileUtils.test (path, FileTest.EXISTS)) {
      tox.send_avatar (path);
      var pixbuf = new Gdk.Pixbuf.from_file_at_scale (path, 48, 48, false);
      this.avatar_image.pixbuf = pixbuf;
    }

    // TODO
    this.entry_name.set_text (tox.username);
    this.entry_status.set_text (tox.status_message);

    this.friendlist.set_sort_func ((row1, row2) => {
      var friend1 = row1 as FriendListRow;
      var friend2 = row2 as FriendListRow;
      return friend1.fr.status - friend2.fr.status;
    });
    this.friendlist.set_filter_func (row => {
      string? search = friend_search.text;
      if (search == null || search.length == 0) {
        return true;
      }
      var friend = row as FriendListRow;
      string name = friend.fr.name;
      return name.down ().index_of (search) != -1;
    });

    this.friendlist.bind_model (this.friends, fr => new FriendListRow (fr as Tox.Friend, this));


    // Add friends from the .tox file.
    uint32[] contacts = this.tox.self_get_friend_list ();
    for (int i = 0; i < contacts.length; i++) {
      uint32 friend_num = contacts[i];
      debug (@"Friend from .tox: num → $friend_num");

      var friend = this.tox.add_friend_by_num (friend_num);
      friend.connected = false;
      friend.position = friends.get_n_items ();
      debug ("Friend name: %s", friend.get_uname ());
      debug ("Friend status_message: %s", friend.get_ustatus_message ());
      debug ("Friend position: %u", friend.position);
      this.friends.append (friend);

      var view_name = "chat-%s".printf (friend.pubkey);
      this.chat_stack.add_named (new ChatView (this.tox, friend, this.chat_stack, view_name), view_name);
    }

    this.toggle_search.bind_property ("active", friend_search_bar, "search-mode-enabled", BindingFlags.BIDIRECTIONAL);

    // profile button
    var add_friend_popover = new Gtk.Popover (button_add_friend_show);
    add_friend_popover.add (add_friend_popover_content);
    button_add_friend_show.popover = add_friend_popover;

    var profile_popover = new Gtk.Popover (button_show_profile);
    profile_popover.add (profile_popover_content);
    button_show_profile.popover = profile_popover;
    tox.bind_property ("id", label_tox_id, "label", BindingFlags.SYNC_CREATE);

    avatar_image.bind_property ("pixbuf", profile_button_avatar, "pixbuf", BindingFlags.SYNC_CREATE);
    entry_status.bind_property ("text", tox, "status_message", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
    entry_status.bind_property ("text", profile_button_status, "label", BindingFlags.SYNC_CREATE);
    tox.bind_property ("username", profile_button_username, "label", BindingFlags.SYNC_CREATE);
    tox.bind_property ("status", profile_button_userstatus, "icon_name", BindingFlags.SYNC_CREATE,
    (bind, src, ref target) => {
      var status = (Tox.UserStatus)src;
      if (status == Tox.UserStatus.ONLINE) {
        target = "user-available";
      } else if (status == Tox.UserStatus.AWAY) {
        target = "user-away";
      } else if (status == Tox.UserStatus.BUSY) {
        target = "user-busy";
      } else if (status == Tox.UserStatus.OFFLINE) {
        target = "user-offline";
      } else if (status == Tox.UserStatus.BLOCKED) {
        assert_not_reached (); // only friends can be blocked
        return false;
      }
      return true;
    });
    tox.bind_property ("connected", button_show_profile, "sensitive", BindingFlags.SYNC_CREATE);

    this.tox.friend_request.connect ((id, message) => {
      var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.NONE, "Friend request from:");
      dialog.secondary_text = @"$id\n\n$message";
      dialog.add_buttons ("Accept", Gtk.ResponseType.ACCEPT, "Reject", Gtk.ResponseType.REJECT);
      dialog.response.connect (response => {
        if (response == Gtk.ResponseType.ACCEPT) {
          var friend = tox.accept_friend_request (id);
          if (friend != null) {
            this.tox.save_data (); // Needed to avoid breaking profiles if app crash.

            friend.position = friends.get_n_items ();
            debug ("Friend position: %u", friend.position);
            friends.append (friend);
            var view_name = "chat-%s".printf (friend.pubkey);
            var chatview = new ChatView (this.tox, friend, this.chat_stack, view_name);
            chat_stack.add_named (chatview, chatview.name);

            var info_message = "The friend request has been accepted. Please wait the contact to appears online.";
            this.notify_message (@"<span color=\"#27ae60\">$info_message</span>", 5000);
          }
        }
        dialog.destroy ();
      });
      dialog.show ();
    });

    this.tox.friend_online.connect ((friend) => {
      if (friend != null) {
        friend.position = friends.get_n_items ();
        debug ("Friend position: %u", friend.position);
        friends.append (friend);
        var view_name = "chat-%s".printf (friend.pubkey);
        chat_stack.add_named (new ChatView (this.tox, friend, this.chat_stack, view_name), view_name);

        // Send our avatar.
        friend.send_avatar ();
      }
    });

    this.notify_message.connect ((message, timeout) =>  {
      this.label_system_notify.use_markup = true;
      this.label_system_notify.set_markup (message);
      this.revealer_system_notify.reveal_child = true;
      Timeout.add (timeout, () => {
        this.revealer_system_notify.reveal_child = false;
        return Source.REMOVE;
      });
    });

    this.tox.run_loop ();
    this.show ();
  }

  ~MainWindow () {
    this.tox.save_data ();
  }

  public void show_add_friend_popover (string toxid = "") {
    if (toxid.length > 0) {
      entry_friend_id.text = toxid;
    }
    if (entry_friend_message.buffer.get_char_count () == 0) {
      entry_friend_message.buffer.text = "Hello! It's " + tox.username + ", let's be friends.";
    }
    button_add_friend_show.active = true;
  }

  [GtkCallback]
  private void show_settings () {
    var settings_view = this.chat_stack.get_child_by_name ("settings");

    if (settings_view != null) {
      this.chat_stack.set_visible_child (settings_view);
    } else {
      var view = new SettingsView (tox);
      this.chat_stack.add_named (view, "settings");
      this.chat_stack.set_visible_child (view);
      this.focused_view = "settings";
    }
  }

  [GtkCallback]
  private void ui_add_friend () {
    debug ("add_friend");
    var tox_id = this.entry_friend_id.text;
    var message = this.entry_friend_message.buffer.text;
    var error_message = "";

    if (tox_id.length == ToxCore.ADDRESS_SIZE*2) { // bytes -> chars
      try {
        var friend = tox.add_friend (tox_id, message);
        this.tox.save_data (); // Needed to avoid breaking profiles if app crash.
        this.entry_friend_id.text = ""; // Clear the entry after adding a friend.
        this.entry_friend_message.buffer.text = "";
        this.label_add_error.set_text ("Add a friend");
        return;
      } catch (Tox.ErrFriendAdd error) {
        debug ("Adding friend failed: %s", error.message);
        error_message = error.message;
      }
    } else if (tox_id.index_of ("@") != -1) {
      error_message = "Ricin doesn't supports ToxDNS yet.";
    } else if (tox_id.strip () == "") {
      error_message = "ToxID can't be empty.";
    } else {
      error_message = "ToxID is invalid.";
    }

    if (error_message.length > 0) {
      this.label_add_error.set_markup (@"<span color=\"#e74c3c\">$error_message</span>");
    }
  }

  [GtkCallback]
  private void show_friend_chatview (Gtk.ListBoxRow row) {
    var friend = (row as FriendListRow).fr;
    var view_name = "chat-%s".printf (friend.pubkey);
    var chat_view = this.chat_stack.get_child_by_name (view_name);
    
    var item = (row as FriendListRow);
    item.unreadCount = 0;
    item.update_icon ();
    
    debug ("ChatView name: %s", view_name);

    if (chat_view != null) {
      (chat_view as ChatView).entry.grab_focus ();
      this.chat_stack.set_visible_child (chat_view);
    }
  }

  [GtkCallback]
  private void set_username_from_entry () {
    this.tox.username = Util.escape_html (this.entry_name.text);
  }

  [GtkCallback]
  private void choose_avatar () {
    var chooser = new Gtk.FileChooserDialog ("Select your avatar",
        this,
        Gtk.FileChooserAction.OPEN,
        "_Cancel", Gtk.ResponseType.CANCEL,
        "_Open", Gtk.ResponseType.ACCEPT);
    var filter = new Gtk.FileFilter ();
    filter.add_custom (Gtk.FileFilterFlags.MIME_TYPE, info => {
      var mime = info.mime_type;
      return mime.has_prefix ("image/") && mime != "image/gif";
    });
    chooser.filter = filter;
    if (chooser.run () == Gtk.ResponseType.ACCEPT) {
      File avatar = chooser.get_file ();
      this.tox.send_avatar (avatar.get_path ());
      this.avatar_image.pixbuf = new Gdk.Pixbuf.from_file_at_scale (avatar.get_path (), 46, 46, true);

      // Copy avatar to ~/.config/tox/avatars/
      try {
        avatar.copy (File.new_for_path (this.avatar_path ()), FileCopyFlags.OVERWRITE);
      } catch (Error err) {
        warning ("Cannot save the avatar in cache: %s", err.message);
      }
    }

    chooser.close ();
  }

  [GtkCallback]
  private void friend_list_update_search () {
    friendlist.invalidate_filter ();
  }

  [GtkCallback]
  private void copy_tox_id () {
    Gtk.Clipboard.get (Gdk.SELECTION_CLIPBOARD).set_text (tox.id, -1);
  }

  [GtkCallback]
  private void change_nospam () {
    tox.nospam = Random.next_int ();
  }

  // TODO: make user status a GAction
  [GtkCallback]
  private void toggle_user_status (Gtk.ToggleButton button) {
    if (button.name == "button_online") {
      tox.status = Tox.UserStatus.ONLINE;
    } else if (button.name == "button_busy") {
      tox.status = Tox.UserStatus.BUSY;
    } else if (button.name == "button_away") {
      tox.status = Tox.UserStatus.AWAY;
    } else {
      assert_not_reached ();
    }
  }
}
