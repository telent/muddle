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


## Basic algorithm

given the server cwd is a maildir
and the client cwd is a maildir
for each message_name on server matching new/name or cur/name:*
  if there is new/name on client, do nothing
  if there is cur/name:* on client, do nothing
  else copy message to c:tmp/`basename message`
   then rename it to c:cur/name:{existing suffix or "2,"}


## Possible optimization

Mail messages - especially short ones - are often quite similar
(common header words, etc), and especially quite similar to messages
they are replies to (quoted text).  If we deflate (zlib compress)
the files that are going to get transferred, we can probably save some
time by prepopulating the compression dictionary from other messages
in the archive before starting.  

 - If we find a reasonably cheap way to look up filenames given
   message ids, we could chase references header and use that as
   dictionary fodder

 - or we could just dump the dictionary to a file after each transfer
   and resume from it for the next one

 - either way, see deflateSetDictionary in http://zlib.net/manual.html
