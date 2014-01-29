# MuDDLe / Maildir Download

Faster than rsync!  Simpler than an IMAP server!

> There are always more efficient algorithms than rsync. If you have
> structured data, and you know precisely the sorts of updates, the
> constraints on the types of updates that can happen to the data,
> then you can always craft a better algorithm than rsync.

  -- Dr. Andrew Tridgell speaking on the Rsync Algorithm at OLS, 21 July, 2000
     http://olstrans.sourceforge.net/release/OLS2000-rsync/OLS2000-rsync.html

In the case of maildir, the above applies in spades

- files once created are never changed

- most of the time when you've got something that looks like a file
  change, it's actually a cross-directory rename

- chances are that you can identify most of the changes on most
  occasions just by looking at the files with ctime newer than the
  last time you did a sync

## Requirements

On the client, it needs Ruby of some kind (possibly 1.9 or later, I've
forgotten how to use earlier versions, but this may be fixed to
accommodate 1.8.7 later)

On the server it needs a find(1) command which supports the `print0`
option, and cpio.  Possibly GNU cpio at that, haven't tested anything
else

## Basic algorithm

given the server cwd is a maildir
and the client cwd is a maildir
for each message_name on server matching new/name or cur/name:*
  if there is new/name or cur/name:* on client, do nothing
  else copy message to c:tmp/`basename message`
   then rename it to c:cur/name:{existing suffix or "2,"}


## Making it faster

Instead of copying the files one at a time, we tar them up and
transfer in bulk, meaning first that the file is big enough for TCP's
window size and congestion control stuff to get its teeth into, and
second that if you enable ssh compression then the later messages will
be compressed using the dictionary created by the earlier ones.
