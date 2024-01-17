namespace G4 {

    [GtkTemplate (ui = "/com/github/neithern/g4music/gtk/mini-bar.ui")]
    public class MiniBar : Adw.ActionRow {
        [GtkChild]
        private unowned Gtk.Image cover_img;
        [GtkChild]
        private unowned Gtk.Label title_label;
        [GtkChild]
        private unowned Gtk.Label time;
        [GtkChild]
        private unowned Gtk.Button prev;
        [GtkChild]
        private unowned Gtk.Button play;

        private int _duration = 0;
        private int _position = 0;

        private CrossFadePaintable _paintable = new CrossFadePaintable ();
        private Adw.Animation? _fade_animation = null;

        construct {
            var controller = new Gtk.GestureClick ();
            controller.released.connect (this.activate);
            add_controller (controller);
            activatable_widget = this;

            cover_img.paintable = new RoundPaintable (_paintable);
            _paintable.queue_draw.connect (cover_img.queue_draw);

            var app = (Application) GLib.Application.get_default ();
            var player = app.player;
            player.duration_changed.connect (on_duration_changed);
            player.position_updated.connect (on_position_changed);
            player.state_changed.connect (on_state_changed);
        }

        public Gdk.Paintable? cover {
            get {
                return _paintable.paintable;
            }
            set {
                _paintable.paintable = value;
                var target = new Adw.CallbackAnimationTarget ((value) => _paintable.fade = value);
                _fade_animation?.pause ();
                _fade_animation = new Adw.TimedAnimation (cover_img, 1 - _paintable.fade, 0, 800, target);
                ((!)_fade_animation).done.connect (() => {
                    _paintable.previous = null;
                    _fade_animation = null;
                });
                _fade_animation?.play ();
            }
        }

        public new string title {
            set {
                title_label.label = value;
            }
        }

        public void size_to_change (int panel_width) {
            prev.visible = panel_width >= 360;
        }

        public override void snapshot (Gtk.Snapshot snapshot) {
            base.snapshot (snapshot);
#if GTK_4_10
            var color = get_color ();
#else
            var color = get_style_context ().get_color ();
#endif
            color.alpha = 0.25f;
            var line_width = scale_factor >= 2 ? 0.5f : 1;
            var rect = Graphene.Rect ();
            rect.init (0, 0, get_width (), line_width);
            snapshot.append_color (color, rect);
        }

        private void on_duration_changed (Gst.ClockTime duration) {
            var value = GstPlayer.to_second (duration);
            if (_duration != (int) value) {
                _duration = (int) value;
                update_time_label ();
            }
        }

        private void on_position_changed (Gst.ClockTime position) {
            var value = GstPlayer.to_second (position);
            if (_position != (int) value) {
                _position = (int) value;
                update_time_label ();
            }
        }

        private void on_state_changed (Gst.State state) {
            var playing = state == Gst.State.PLAYING;
            play.icon_name = playing ? "media-playback-pause-symbolic" : "media-playback-start-symbolic";
        }

        private void update_time_label () {
            if (_duration > 0)
                time.label = format_time (_position) + "/" + format_time (_duration);
            else
                time.label = "";
        }
    }
}
