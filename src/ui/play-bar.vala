namespace G4 {

    [GtkTemplate (ui = "/com/github/neithern/g4music/gtk/play-bar.ui")]
    public class PlayBar : Gtk.Box {
        [GtkChild]
        private unowned Gtk.Scale seek;
        [GtkChild]
        private unowned PeakBar peak_bar;
        [GtkChild]
        private unowned Gtk.Label positive;
        [GtkChild]
        private unowned Gtk.Label negative;
        [GtkChild]
        private unowned Gtk.ToggleButton repeat;
        [GtkChild]
        private unowned Gtk.Button play;
        [GtkChild]
        private unowned VolumeButton volume;

        private int _duration = 0;
        private int _position = 0;
        private bool _remain_progress = false;

        public signal void position_seeked (double position);

        construct {
            var app = (Application) GLib.Application.get_default ();
            var player = app.player;

            seek.set_range (0, _duration);
            seek.adjust_bounds.connect ((value) => {
                player.seek (GstPlayer.from_second (value));
                position_seeked (value);
            });

            make_widget_clickable (negative).pressed.connect (() => remain_progress = !remain_progress);

            repeat.toggled.connect (() => {
                repeat.icon_name = repeat.active ? "media-playlist-repeat-song-symbolic" : "media-playlist-repeat-symbolic";
                app.single_loop = ! app.single_loop;
            });

            player.bind_property ("volume", volume, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

            player.duration_changed.connect (on_duration_changed);
            player.position_updated.connect (on_position_changed);
            player.state_changed.connect (on_state_changed);

            var settings = app.settings;
            settings.bind ("show-peak", peak_bar, "visible", SettingsBindFlags.DEFAULT);
            settings.bind ("peak-characters", peak_bar, "characters", SettingsBindFlags.DEFAULT);
            settings.bind ("remain-progress", this, "remain-progress", SettingsBindFlags.DEFAULT);
        }

        public double peak {
            set {
                peak_bar.peak = value;
            }
        }

        public double position {
            get {
                return seek.get_value ();
            }
        }

        public bool remain_progress {
            get {
                return _remain_progress;
            }
            set {
                _remain_progress = value;
                update_negative_label ();
            }
        }

        public void on_size_changed (int bar_width) {
            var text_width = int.max (positive.get_width (), negative.get_width ());
            peak_bar.width_request = bar_width - (text_width + positive.margin_start + negative.margin_end) * 2;
        }

        private void on_duration_changed (Gst.ClockTime duration) {
            var value = GstPlayer.to_second (duration);
            _duration = (int) (value + 0.5);
            seek.set_range (0, _duration);
            update_negative_label ();
        }

        private void on_position_changed (Gst.ClockTime position) {
            var value = GstPlayer.to_second (position);
            if (_position != (int) value) {
                _position = (int) value;
                positive.label = format_time (_position);
                if (_remain_progress)
                    negative.label = "-" + format_time (_duration - _position);
            }
            seek.set_value (value);
        }

        private void on_state_changed (Gst.State state) {
            var playing = state == Gst.State.PLAYING;
            play.icon_name = playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic";
        }

        private void update_negative_label () {
            if (_remain_progress)
                negative.label = "-" + format_time (_duration - _position);
            else
                negative.label = format_time (_duration);
        }
    }

    public static string format_time (int seconds) {
        var sb = new StringBuilder ();
        var hours = seconds / 3600;
        var minutes = seconds / 60;
        seconds -= minutes * 60;
        if (hours > 0) {
            minutes -= hours * 60;
            sb.printf ("%d:%02d:%02d", hours, minutes, seconds);
        } else {
            sb.printf ("%d:%02d", minutes, seconds);
        }
        return sb.str;
    }

    public static Gtk.GestureClick make_widget_clickable (Gtk.Widget label) {
        var controller = new Gtk.GestureClick ();
        label.add_controller (controller);
        label.set_cursor_from_name ("hand");
        return controller;
    }
}
