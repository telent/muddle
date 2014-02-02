# MuDDLe / Maildir Download

Faster than rsync!  Simpler than an IMAP server!

As Dr. Andrew Tridgell himself said:

> There are always more efficient algorithms than rsync. If you have
> structured data, and you know precisely the sorts of updates, the
> constraints on the types of updates that can happen to the data,
> then you can always craft a better algorithm than rsync.

  -- speaking on the Rsync Algorithm at OLS, 21 July, 2000
     http://olstrans.sourceforge.net/release/OLS2000-rsync/OLS2000-rsync.html

In the case of maildir, the above applies in spades:

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


## Invoking it

Do something like

```
$ ruby ./muddle.rb --verbose remotename@mail.example.com:/home/remotename/Maildir ~/mail-from-server/
```

varying the paths and directories as appropriate.  You may first wish
to edit your `.ssh/config` file to insert a stanza for your mail host
that turns on compression:

```
Host mail.example.com
        Compression yes
```

(A future version will install as a Gem, and probably will also add a
-C option so that you can turn compression on only for maildir syncing
and not for everything)


## Basic algorithm

* given the server cwd is a maildir
* and the client cwd is a maildir
* then for each message_name on server matching new/name or cur/name:*
    *  unless there is already new/name or cur/name:* on client
        * copy message to client:tmp/$(basename message)
        * then rename it to client:cur/name:{existing suffix or "2,"}


## Making it faster

Instead of copying the files one at a time, we tar them up and
transfer in bulk, meaning first that the file is big enough for TCP's
window size and congestion control stuff to get its teeth into, and
second that if you enable ssh compression then the later messages will
be compressed using the dictionary created by the earlier ones.

