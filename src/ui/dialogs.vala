namespace G4 {

    public class Dialog : Adw.Dialog {

        public new void present (Gtk.Widget? parent) {
            content_width = compute_dialog_width (parent);
            base.present (parent);
        }
    }

    public int compute_dialog_width (Gtk.Widget? parent) {
        var width = parent?.get_width () ?? ContentWidth.MIN;
        if (width > 360)
            width = (width * 3 / 8).clamp (360, ContentWidth.MAX);
        return width;
    }

    public void show_about_dialog (Application app) {
        string[] authors = { "Nanling" };
        /* Translators: Replace "translator-credits" with your names, one name per line */
        var translator_credits = _("translator-credits");
        var website = "https://gitlab.gnome.org/neithern/g4music";
        var parent = Window.get_default ();
        var win = new Adw.AboutDialog ();
        run_idle_once (() => {
            if (parent != null && ((!)parent).get_width () < win.width_request)
                ((!)parent).default_width = win.width_request;
        });
        win.application_icon = app.application_id;
        win.application_name = app.name;
        win.version = Config.VERSION;
        win.license_type = Gtk.License.GPL_3_0;
        win.developers = authors;
        win.website = website;
        win.issue_url = "https://gitlab.gnome.org/neithern/g4music/issues";
        win.translator_credits = translator_credits;
        win.present (parent);
    }

    public async bool show_alert_dialog (string text, Gtk.Window? parent = null) {
        var result = false;
        var dialog = new Adw.AlertDialog (null, text);
        dialog.add_response ("no", _("No"));
        dialog.add_response ("yes", _("Yes"));
        dialog.default_response = "yes";
        dialog.response.connect ((id) => {
            result = id == "yes";
            Idle.add (show_alert_dialog.callback);
        });
        dialog.present (parent);
        yield;
        return result;
    }

    public async File? show_save_file_dialog (Gtk.Window? parent, File? initial = null, Gtk.FileFilter[]? filters = null) {
        Gtk.FileFilter? default_filter = filters != null && ((!)filters).length > 0 ? ((!)filters)[0] : (Gtk.FileFilter?) null;
        var filter_list = new ListStore (typeof (Gtk.FileFilter));
        if (filters != null) {
            foreach (var filter in (!)filters) 
                filter_list.append (filter);
        }
        var dialog = new Gtk.FileDialog ();
        dialog.filters = filter_list;
        dialog.modal = true;
        dialog.set_default_filter (default_filter);
        dialog.set_initial_file (initial);
        try {
            return yield dialog.save (parent, null);
        } catch (Error e) {
        }
        return null;
    }

    public async File? show_select_folder_dialog (Gtk.Window? parent, File? initial = null) {
        var dialog = new Gtk.FileDialog ();
        dialog.set_initial_folder (initial);
        dialog.modal = true;
        try {
            return yield dialog.select_folder (parent, null);
        } catch (Error e) {
        }
        return null;
    }
}
