# From http://ruby-gnome2.sourceforge.jp/hiki.cgi?tips_threads
#
# This is a crucial "tip," and in fact qualifies, I believe, as a major warning
# or fix for using Ruby with the Gtk library.
# 
# The warning is this: If you call Gtk methods from outside of Gtk's main thread,
# there is a chance that the Ruby interpreter (not merely your Ruby application!)
# will crash with a segmentation fault (seg fault) error, seemingly at random.
# This is not an exception you can catch. It is fatal and crippling, and very
# difficult to debug.
# 
# You might be using Ruby threads even without knowing! For example, if you
# receive events or callbacks to your Ruby methods or blocks from another library
# or service, these calls may very well be occurring on other threads. If that's
#   the case, and you call Gtk from within your callbacks, you risk a seg fault.
# 
# Otherwise you might have your own worker thread in the background doing some
#   work, which occasionally needs to call Gtk to update a widget. 
#     
#     (Side note: If you are using Ruby threads, be sure to protect your
#      thread-shared resources with either a Monitor or a Mutex! The difference:
#        monitors are safer, in that they are re-entrable from the same thread;
#      mutexes aren't, but perform better.)
#
# Usage is very simple:

# Start your Gtk application by calling Gtk.main_with_queue rather than
# Gtk.main. The "timeout" argument is in milliseconds, and it is the maximum
# time that can pass until queued blocks get called: 100 should be fine. 
# 
# Whenever you need to queue a call, use Gtk.queue. For example:
# def my_event_callback
#   Gtk.queue do
#     @image.pixbuf = Gdk::Pixbuf.new @image_path, width, height
#   end
# end
#
# Issues:
#   1. Keep your queued blocks lean. Do all your CPU-intensive work outside of
#      the queued block. This will help keep Gtk responsive.

require 'monitor'
module Gtk
  GTK_PENDING_BLOCKS = []
  GTK_PENDING_BLOCKS_LOCK = ::Monitor.new

  def Gtk.queue &block
    if Thread.current == Thread.main
      block.call
    else
      GTK_PENDING_BLOCKS_LOCK.synchronize do
        GTK_PENDING_BLOCKS << block
      end
    end
  end

  def Gtk.main_with_queue timeout = 100
    Gtk.timeout_add timeout do
      GTK_PENDING_BLOCKS_LOCK.synchronize do
        for block in GTK_PENDING_BLOCKS
          block.call
        end
        GTK_PENDING_BLOCKS.clear
      end
      true
    end
    Gtk.main
  end
end
