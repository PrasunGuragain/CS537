
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 90 10 00       	mov    $0x109000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc f0 56 11 80       	mov    $0x801156f0,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 34 2a 10 80       	mov    $0x80102a34,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	57                   	push   %edi
80100038:	56                   	push   %esi
80100039:	53                   	push   %ebx
8010003a:	83 ec 18             	sub    $0x18,%esp
8010003d:	89 c6                	mov    %eax,%esi
8010003f:	89 d7                	mov    %edx,%edi
  struct buf *b;

  acquire(&bcache.lock);
80100041:	68 20 a5 10 80       	push   $0x8010a520
80100046:	e8 35 3c 00 00       	call   80103c80 <acquire>

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010004b:	8b 1d 70 ec 10 80    	mov    0x8010ec70,%ebx
80100051:	83 c4 10             	add    $0x10,%esp
80100054:	eb 03                	jmp    80100059 <bget+0x25>
80100056:	8b 5b 54             	mov    0x54(%ebx),%ebx
80100059:	81 fb 1c ec 10 80    	cmp    $0x8010ec1c,%ebx
8010005f:	74 30                	je     80100091 <bget+0x5d>
    if(b->dev == dev && b->blockno == blockno){
80100061:	39 73 04             	cmp    %esi,0x4(%ebx)
80100064:	75 f0                	jne    80100056 <bget+0x22>
80100066:	39 7b 08             	cmp    %edi,0x8(%ebx)
80100069:	75 eb                	jne    80100056 <bget+0x22>
      b->refcnt++;
8010006b:	8b 43 4c             	mov    0x4c(%ebx),%eax
8010006e:	83 c0 01             	add    $0x1,%eax
80100071:	89 43 4c             	mov    %eax,0x4c(%ebx)
      release(&bcache.lock);
80100074:	83 ec 0c             	sub    $0xc,%esp
80100077:	68 20 a5 10 80       	push   $0x8010a520
8010007c:	e8 64 3c 00 00       	call   80103ce5 <release>
      acquiresleep(&b->lock);
80100081:	8d 43 0c             	lea    0xc(%ebx),%eax
80100084:	89 04 24             	mov    %eax,(%esp)
80100087:	e8 e0 39 00 00       	call   80103a6c <acquiresleep>
      return b;
8010008c:	83 c4 10             	add    $0x10,%esp
8010008f:	eb 4c                	jmp    801000dd <bget+0xa9>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100091:	8b 1d 6c ec 10 80    	mov    0x8010ec6c,%ebx
80100097:	eb 03                	jmp    8010009c <bget+0x68>
80100099:	8b 5b 50             	mov    0x50(%ebx),%ebx
8010009c:	81 fb 1c ec 10 80    	cmp    $0x8010ec1c,%ebx
801000a2:	74 43                	je     801000e7 <bget+0xb3>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
801000a4:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
801000a8:	75 ef                	jne    80100099 <bget+0x65>
801000aa:	f6 03 04             	testb  $0x4,(%ebx)
801000ad:	75 ea                	jne    80100099 <bget+0x65>
      b->dev = dev;
801000af:	89 73 04             	mov    %esi,0x4(%ebx)
      b->blockno = blockno;
801000b2:	89 7b 08             	mov    %edi,0x8(%ebx)
      b->flags = 0;
801000b5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
      b->refcnt = 1;
801000bb:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
      release(&bcache.lock);
801000c2:	83 ec 0c             	sub    $0xc,%esp
801000c5:	68 20 a5 10 80       	push   $0x8010a520
801000ca:	e8 16 3c 00 00       	call   80103ce5 <release>
      acquiresleep(&b->lock);
801000cf:	8d 43 0c             	lea    0xc(%ebx),%eax
801000d2:	89 04 24             	mov    %eax,(%esp)
801000d5:	e8 92 39 00 00       	call   80103a6c <acquiresleep>
      return b;
801000da:	83 c4 10             	add    $0x10,%esp
    }
  }
  panic("bget: no buffers");
}
801000dd:	89 d8                	mov    %ebx,%eax
801000df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
  panic("bget: no buffers");
801000e7:	83 ec 0c             	sub    $0xc,%esp
801000ea:	68 60 68 10 80       	push   $0x80106860
801000ef:	e8 54 02 00 00       	call   80100348 <panic>

801000f4 <binit>:
{
801000f4:	55                   	push   %ebp
801000f5:	89 e5                	mov    %esp,%ebp
801000f7:	53                   	push   %ebx
801000f8:	83 ec 0c             	sub    $0xc,%esp
  initlock(&bcache.lock, "bcache");
801000fb:	68 71 68 10 80       	push   $0x80106871
80100100:	68 20 a5 10 80       	push   $0x8010a520
80100105:	e8 3a 3a 00 00       	call   80103b44 <initlock>
  bcache.head.prev = &bcache.head;
8010010a:	c7 05 6c ec 10 80 1c 	movl   $0x8010ec1c,0x8010ec6c
80100111:	ec 10 80 
  bcache.head.next = &bcache.head;
80100114:	c7 05 70 ec 10 80 1c 	movl   $0x8010ec1c,0x8010ec70
8010011b:	ec 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010011e:	83 c4 10             	add    $0x10,%esp
80100121:	bb 54 a5 10 80       	mov    $0x8010a554,%ebx
80100126:	eb 37                	jmp    8010015f <binit+0x6b>
    b->next = bcache.head.next;
80100128:	a1 70 ec 10 80       	mov    0x8010ec70,%eax
8010012d:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
80100130:	c7 43 50 1c ec 10 80 	movl   $0x8010ec1c,0x50(%ebx)
    initsleeplock(&b->lock, "buffer");
80100137:	83 ec 08             	sub    $0x8,%esp
8010013a:	68 78 68 10 80       	push   $0x80106878
8010013f:	8d 43 0c             	lea    0xc(%ebx),%eax
80100142:	50                   	push   %eax
80100143:	e8 f1 38 00 00       	call   80103a39 <initsleeplock>
    bcache.head.next->prev = b;
80100148:	a1 70 ec 10 80       	mov    0x8010ec70,%eax
8010014d:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
80100150:	89 1d 70 ec 10 80    	mov    %ebx,0x8010ec70
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100156:	81 c3 5c 02 00 00    	add    $0x25c,%ebx
8010015c:	83 c4 10             	add    $0x10,%esp
8010015f:	81 fb 1c ec 10 80    	cmp    $0x8010ec1c,%ebx
80100165:	72 c1                	jb     80100128 <binit+0x34>
}
80100167:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010016a:	c9                   	leave  
8010016b:	c3                   	ret    

8010016c <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
8010016c:	55                   	push   %ebp
8010016d:	89 e5                	mov    %esp,%ebp
8010016f:	53                   	push   %ebx
80100170:	83 ec 04             	sub    $0x4,%esp
  struct buf *b;

  b = bget(dev, blockno);
80100173:	8b 55 0c             	mov    0xc(%ebp),%edx
80100176:	8b 45 08             	mov    0x8(%ebp),%eax
80100179:	e8 b6 fe ff ff       	call   80100034 <bget>
8010017e:	89 c3                	mov    %eax,%ebx
  if((b->flags & B_VALID) == 0) {
80100180:	f6 00 02             	testb  $0x2,(%eax)
80100183:	74 07                	je     8010018c <bread+0x20>
    iderw(b);
  }
  return b;
}
80100185:	89 d8                	mov    %ebx,%eax
80100187:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010018a:	c9                   	leave  
8010018b:	c3                   	ret    
    iderw(b);
8010018c:	83 ec 0c             	sub    $0xc,%esp
8010018f:	50                   	push   %eax
80100190:	e8 62 1c 00 00       	call   80101df7 <iderw>
80100195:	83 c4 10             	add    $0x10,%esp
  return b;
80100198:	eb eb                	jmp    80100185 <bread+0x19>

8010019a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
8010019a:	55                   	push   %ebp
8010019b:	89 e5                	mov    %esp,%ebp
8010019d:	53                   	push   %ebx
8010019e:	83 ec 10             	sub    $0x10,%esp
801001a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001a4:	8d 43 0c             	lea    0xc(%ebx),%eax
801001a7:	50                   	push   %eax
801001a8:	e8 49 39 00 00       	call   80103af6 <holdingsleep>
801001ad:	83 c4 10             	add    $0x10,%esp
801001b0:	85 c0                	test   %eax,%eax
801001b2:	74 14                	je     801001c8 <bwrite+0x2e>
    panic("bwrite");
  b->flags |= B_DIRTY;
801001b4:	83 0b 04             	orl    $0x4,(%ebx)
  iderw(b);
801001b7:	83 ec 0c             	sub    $0xc,%esp
801001ba:	53                   	push   %ebx
801001bb:	e8 37 1c 00 00       	call   80101df7 <iderw>
}
801001c0:	83 c4 10             	add    $0x10,%esp
801001c3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801001c6:	c9                   	leave  
801001c7:	c3                   	ret    
    panic("bwrite");
801001c8:	83 ec 0c             	sub    $0xc,%esp
801001cb:	68 7f 68 10 80       	push   $0x8010687f
801001d0:	e8 73 01 00 00       	call   80100348 <panic>

801001d5 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
801001d5:	55                   	push   %ebp
801001d6:	89 e5                	mov    %esp,%ebp
801001d8:	56                   	push   %esi
801001d9:	53                   	push   %ebx
801001da:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holdingsleep(&b->lock))
801001dd:	8d 73 0c             	lea    0xc(%ebx),%esi
801001e0:	83 ec 0c             	sub    $0xc,%esp
801001e3:	56                   	push   %esi
801001e4:	e8 0d 39 00 00       	call   80103af6 <holdingsleep>
801001e9:	83 c4 10             	add    $0x10,%esp
801001ec:	85 c0                	test   %eax,%eax
801001ee:	74 6b                	je     8010025b <brelse+0x86>
    panic("brelse");

  releasesleep(&b->lock);
801001f0:	83 ec 0c             	sub    $0xc,%esp
801001f3:	56                   	push   %esi
801001f4:	e8 c2 38 00 00       	call   80103abb <releasesleep>

  acquire(&bcache.lock);
801001f9:	c7 04 24 20 a5 10 80 	movl   $0x8010a520,(%esp)
80100200:	e8 7b 3a 00 00       	call   80103c80 <acquire>
  b->refcnt--;
80100205:	8b 43 4c             	mov    0x4c(%ebx),%eax
80100208:	83 e8 01             	sub    $0x1,%eax
8010020b:	89 43 4c             	mov    %eax,0x4c(%ebx)
  if (b->refcnt == 0) {
8010020e:	83 c4 10             	add    $0x10,%esp
80100211:	85 c0                	test   %eax,%eax
80100213:	75 2f                	jne    80100244 <brelse+0x6f>
    // no one is waiting for it.
    b->next->prev = b->prev;
80100215:	8b 43 54             	mov    0x54(%ebx),%eax
80100218:	8b 53 50             	mov    0x50(%ebx),%edx
8010021b:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
8010021e:	8b 43 50             	mov    0x50(%ebx),%eax
80100221:	8b 53 54             	mov    0x54(%ebx),%edx
80100224:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
80100227:	a1 70 ec 10 80       	mov    0x8010ec70,%eax
8010022c:	89 43 54             	mov    %eax,0x54(%ebx)
    b->prev = &bcache.head;
8010022f:	c7 43 50 1c ec 10 80 	movl   $0x8010ec1c,0x50(%ebx)
    bcache.head.next->prev = b;
80100236:	a1 70 ec 10 80       	mov    0x8010ec70,%eax
8010023b:	89 58 50             	mov    %ebx,0x50(%eax)
    bcache.head.next = b;
8010023e:	89 1d 70 ec 10 80    	mov    %ebx,0x8010ec70
  }
  
  release(&bcache.lock);
80100244:	83 ec 0c             	sub    $0xc,%esp
80100247:	68 20 a5 10 80       	push   $0x8010a520
8010024c:	e8 94 3a 00 00       	call   80103ce5 <release>
}
80100251:	83 c4 10             	add    $0x10,%esp
80100254:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100257:	5b                   	pop    %ebx
80100258:	5e                   	pop    %esi
80100259:	5d                   	pop    %ebp
8010025a:	c3                   	ret    
    panic("brelse");
8010025b:	83 ec 0c             	sub    $0xc,%esp
8010025e:	68 86 68 10 80       	push   $0x80106886
80100263:	e8 e0 00 00 00       	call   80100348 <panic>

80100268 <consoleread>:
  }
}

int
consoleread(struct inode *ip, char *dst, int n)
{
80100268:	55                   	push   %ebp
80100269:	89 e5                	mov    %esp,%ebp
8010026b:	57                   	push   %edi
8010026c:	56                   	push   %esi
8010026d:	53                   	push   %ebx
8010026e:	83 ec 28             	sub    $0x28,%esp
80100271:	8b 7d 08             	mov    0x8(%ebp),%edi
80100274:	8b 75 0c             	mov    0xc(%ebp),%esi
80100277:	8b 5d 10             	mov    0x10(%ebp),%ebx
  uint target;
  int c;

  iunlock(ip);
8010027a:	57                   	push   %edi
8010027b:	e8 b1 13 00 00       	call   80101631 <iunlock>
  target = n;
80100280:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  acquire(&cons.lock);
80100283:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
8010028a:	e8 f1 39 00 00       	call   80103c80 <acquire>
  while(n > 0){
8010028f:	83 c4 10             	add    $0x10,%esp
80100292:	85 db                	test   %ebx,%ebx
80100294:	0f 8e 8f 00 00 00    	jle    80100329 <consoleread+0xc1>
    while(input.r == input.w){
8010029a:	a1 00 ef 10 80       	mov    0x8010ef00,%eax
8010029f:	3b 05 04 ef 10 80    	cmp    0x8010ef04,%eax
801002a5:	75 47                	jne    801002ee <consoleread+0x86>
      if(myproc()->killed){
801002a7:	e8 6f 2f 00 00       	call   8010321b <myproc>
801002ac:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
801002b0:	75 17                	jne    801002c9 <consoleread+0x61>
        release(&cons.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
801002b2:	83 ec 08             	sub    $0x8,%esp
801002b5:	68 20 ef 10 80       	push   $0x8010ef20
801002ba:	68 00 ef 10 80       	push   $0x8010ef00
801002bf:	e8 b9 34 00 00       	call   8010377d <sleep>
801002c4:	83 c4 10             	add    $0x10,%esp
801002c7:	eb d1                	jmp    8010029a <consoleread+0x32>
        release(&cons.lock);
801002c9:	83 ec 0c             	sub    $0xc,%esp
801002cc:	68 20 ef 10 80       	push   $0x8010ef20
801002d1:	e8 0f 3a 00 00       	call   80103ce5 <release>
        ilock(ip);
801002d6:	89 3c 24             	mov    %edi,(%esp)
801002d9:	e8 91 12 00 00       	call   8010156f <ilock>
        return -1;
801002de:	83 c4 10             	add    $0x10,%esp
801002e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  release(&cons.lock);
  ilock(ip);

  return target - n;
}
801002e6:	8d 65 f4             	lea    -0xc(%ebp),%esp
801002e9:	5b                   	pop    %ebx
801002ea:	5e                   	pop    %esi
801002eb:	5f                   	pop    %edi
801002ec:	5d                   	pop    %ebp
801002ed:	c3                   	ret    
    c = input.buf[input.r++ % INPUT_BUF];
801002ee:	8d 50 01             	lea    0x1(%eax),%edx
801002f1:	89 15 00 ef 10 80    	mov    %edx,0x8010ef00
801002f7:	89 c2                	mov    %eax,%edx
801002f9:	83 e2 7f             	and    $0x7f,%edx
801002fc:	0f b6 92 80 ee 10 80 	movzbl -0x7fef1180(%edx),%edx
80100303:	0f be ca             	movsbl %dl,%ecx
    if(c == C('D')){  // EOF
80100306:	80 fa 04             	cmp    $0x4,%dl
80100309:	74 14                	je     8010031f <consoleread+0xb7>
    *dst++ = c;
8010030b:	8d 46 01             	lea    0x1(%esi),%eax
8010030e:	88 16                	mov    %dl,(%esi)
    --n;
80100310:	83 eb 01             	sub    $0x1,%ebx
    if(c == '\n')
80100313:	83 f9 0a             	cmp    $0xa,%ecx
80100316:	74 11                	je     80100329 <consoleread+0xc1>
    *dst++ = c;
80100318:	89 c6                	mov    %eax,%esi
8010031a:	e9 73 ff ff ff       	jmp    80100292 <consoleread+0x2a>
      if(n < target){
8010031f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
80100322:	73 05                	jae    80100329 <consoleread+0xc1>
        input.r--;
80100324:	a3 00 ef 10 80       	mov    %eax,0x8010ef00
  release(&cons.lock);
80100329:	83 ec 0c             	sub    $0xc,%esp
8010032c:	68 20 ef 10 80       	push   $0x8010ef20
80100331:	e8 af 39 00 00       	call   80103ce5 <release>
  ilock(ip);
80100336:	89 3c 24             	mov    %edi,(%esp)
80100339:	e8 31 12 00 00       	call   8010156f <ilock>
  return target - n;
8010033e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100341:	29 d8                	sub    %ebx,%eax
80100343:	83 c4 10             	add    $0x10,%esp
80100346:	eb 9e                	jmp    801002e6 <consoleread+0x7e>

80100348 <panic>:
{
80100348:	55                   	push   %ebp
80100349:	89 e5                	mov    %esp,%ebp
8010034b:	53                   	push   %ebx
8010034c:	83 ec 34             	sub    $0x34,%esp
}

static inline void
cli(void)
{
  asm volatile("cli");
8010034f:	fa                   	cli    
  cons.locking = 0;
80100350:	c7 05 54 ef 10 80 00 	movl   $0x0,0x8010ef54
80100357:	00 00 00 
  cprintf("lapicid %d: panic: ", lapicid());
8010035a:	e8 01 20 00 00       	call   80102360 <lapicid>
8010035f:	83 ec 08             	sub    $0x8,%esp
80100362:	50                   	push   %eax
80100363:	68 8d 68 10 80       	push   $0x8010688d
80100368:	e8 9a 02 00 00       	call   80100607 <cprintf>
  cprintf(s);
8010036d:	83 c4 04             	add    $0x4,%esp
80100370:	ff 75 08             	push   0x8(%ebp)
80100373:	e8 8f 02 00 00       	call   80100607 <cprintf>
  cprintf("\n");
80100378:	c7 04 24 c7 71 10 80 	movl   $0x801071c7,(%esp)
8010037f:	e8 83 02 00 00       	call   80100607 <cprintf>
  getcallerpcs(&s, pcs);
80100384:	83 c4 08             	add    $0x8,%esp
80100387:	8d 45 d0             	lea    -0x30(%ebp),%eax
8010038a:	50                   	push   %eax
8010038b:	8d 45 08             	lea    0x8(%ebp),%eax
8010038e:	50                   	push   %eax
8010038f:	e8 cb 37 00 00       	call   80103b5f <getcallerpcs>
  for(i=0; i<10; i++)
80100394:	83 c4 10             	add    $0x10,%esp
80100397:	bb 00 00 00 00       	mov    $0x0,%ebx
8010039c:	eb 17                	jmp    801003b5 <panic+0x6d>
    cprintf(" %p", pcs[i]);
8010039e:	83 ec 08             	sub    $0x8,%esp
801003a1:	ff 74 9d d0          	push   -0x30(%ebp,%ebx,4)
801003a5:	68 a1 68 10 80       	push   $0x801068a1
801003aa:	e8 58 02 00 00       	call   80100607 <cprintf>
  for(i=0; i<10; i++)
801003af:	83 c3 01             	add    $0x1,%ebx
801003b2:	83 c4 10             	add    $0x10,%esp
801003b5:	83 fb 09             	cmp    $0x9,%ebx
801003b8:	7e e4                	jle    8010039e <panic+0x56>
  panicked = 1; // freeze other CPU
801003ba:	c7 05 58 ef 10 80 01 	movl   $0x1,0x8010ef58
801003c1:	00 00 00 
  for(;;)
801003c4:	eb fe                	jmp    801003c4 <panic+0x7c>

801003c6 <cgaputc>:
{
801003c6:	55                   	push   %ebp
801003c7:	89 e5                	mov    %esp,%ebp
801003c9:	57                   	push   %edi
801003ca:	56                   	push   %esi
801003cb:	53                   	push   %ebx
801003cc:	83 ec 0c             	sub    $0xc,%esp
801003cf:	89 c3                	mov    %eax,%ebx
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003d1:	bf d4 03 00 00       	mov    $0x3d4,%edi
801003d6:	b8 0e 00 00 00       	mov    $0xe,%eax
801003db:	89 fa                	mov    %edi,%edx
801003dd:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003de:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
801003e3:	89 ca                	mov    %ecx,%edx
801003e5:	ec                   	in     (%dx),%al
  pos = inb(CRTPORT+1) << 8;
801003e6:	0f b6 f0             	movzbl %al,%esi
801003e9:	c1 e6 08             	shl    $0x8,%esi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801003ec:	b8 0f 00 00 00       	mov    $0xf,%eax
801003f1:	89 fa                	mov    %edi,%edx
801003f3:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801003f4:	89 ca                	mov    %ecx,%edx
801003f6:	ec                   	in     (%dx),%al
  pos |= inb(CRTPORT+1);
801003f7:	0f b6 c8             	movzbl %al,%ecx
801003fa:	09 f1                	or     %esi,%ecx
  if(c == '\n')
801003fc:	83 fb 0a             	cmp    $0xa,%ebx
801003ff:	74 60                	je     80100461 <cgaputc+0x9b>
  else if(c == BACKSPACE){
80100401:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
80100407:	74 79                	je     80100482 <cgaputc+0xbc>
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
80100409:	0f b6 c3             	movzbl %bl,%eax
8010040c:	8d 59 01             	lea    0x1(%ecx),%ebx
8010040f:	80 cc 07             	or     $0x7,%ah
80100412:	66 89 84 09 00 80 0b 	mov    %ax,-0x7ff48000(%ecx,%ecx,1)
80100419:	80 
  if(pos < 0 || pos > 25*80)
8010041a:	81 fb d0 07 00 00    	cmp    $0x7d0,%ebx
80100420:	77 6d                	ja     8010048f <cgaputc+0xc9>
  if((pos/80) >= 24){  // Scroll up.
80100422:	81 fb 7f 07 00 00    	cmp    $0x77f,%ebx
80100428:	7f 72                	jg     8010049c <cgaputc+0xd6>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010042a:	be d4 03 00 00       	mov    $0x3d4,%esi
8010042f:	b8 0e 00 00 00       	mov    $0xe,%eax
80100434:	89 f2                	mov    %esi,%edx
80100436:	ee                   	out    %al,(%dx)
  outb(CRTPORT+1, pos>>8);
80100437:	0f b6 c7             	movzbl %bh,%eax
8010043a:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
8010043f:	89 ca                	mov    %ecx,%edx
80100441:	ee                   	out    %al,(%dx)
80100442:	b8 0f 00 00 00       	mov    $0xf,%eax
80100447:	89 f2                	mov    %esi,%edx
80100449:	ee                   	out    %al,(%dx)
8010044a:	89 d8                	mov    %ebx,%eax
8010044c:	89 ca                	mov    %ecx,%edx
8010044e:	ee                   	out    %al,(%dx)
  crt[pos] = ' ' | 0x0700;
8010044f:	66 c7 84 1b 00 80 0b 	movw   $0x720,-0x7ff48000(%ebx,%ebx,1)
80100456:	80 20 07 
}
80100459:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010045c:	5b                   	pop    %ebx
8010045d:	5e                   	pop    %esi
8010045e:	5f                   	pop    %edi
8010045f:	5d                   	pop    %ebp
80100460:	c3                   	ret    
    pos += 80 - pos%80;
80100461:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100466:	89 c8                	mov    %ecx,%eax
80100468:	f7 ea                	imul   %edx
8010046a:	c1 fa 05             	sar    $0x5,%edx
8010046d:	8d 04 92             	lea    (%edx,%edx,4),%eax
80100470:	c1 e0 04             	shl    $0x4,%eax
80100473:	89 ca                	mov    %ecx,%edx
80100475:	29 c2                	sub    %eax,%edx
80100477:	bb 50 00 00 00       	mov    $0x50,%ebx
8010047c:	29 d3                	sub    %edx,%ebx
8010047e:	01 cb                	add    %ecx,%ebx
80100480:	eb 98                	jmp    8010041a <cgaputc+0x54>
    if(pos > 0) --pos;
80100482:	85 c9                	test   %ecx,%ecx
80100484:	7e 05                	jle    8010048b <cgaputc+0xc5>
80100486:	8d 59 ff             	lea    -0x1(%ecx),%ebx
80100489:	eb 8f                	jmp    8010041a <cgaputc+0x54>
  pos |= inb(CRTPORT+1);
8010048b:	89 cb                	mov    %ecx,%ebx
8010048d:	eb 8b                	jmp    8010041a <cgaputc+0x54>
    panic("pos under/overflow");
8010048f:	83 ec 0c             	sub    $0xc,%esp
80100492:	68 a5 68 10 80       	push   $0x801068a5
80100497:	e8 ac fe ff ff       	call   80100348 <panic>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
8010049c:	83 ec 04             	sub    $0x4,%esp
8010049f:	68 60 0e 00 00       	push   $0xe60
801004a4:	68 a0 80 0b 80       	push   $0x800b80a0
801004a9:	68 00 80 0b 80       	push   $0x800b8000
801004ae:	e8 f1 38 00 00       	call   80103da4 <memmove>
    pos -= 80;
801004b3:	83 eb 50             	sub    $0x50,%ebx
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801004b6:	b8 80 07 00 00       	mov    $0x780,%eax
801004bb:	29 d8                	sub    %ebx,%eax
801004bd:	8d 94 1b 00 80 0b 80 	lea    -0x7ff48000(%ebx,%ebx,1),%edx
801004c4:	83 c4 0c             	add    $0xc,%esp
801004c7:	01 c0                	add    %eax,%eax
801004c9:	50                   	push   %eax
801004ca:	6a 00                	push   $0x0
801004cc:	52                   	push   %edx
801004cd:	e8 5a 38 00 00       	call   80103d2c <memset>
801004d2:	83 c4 10             	add    $0x10,%esp
801004d5:	e9 50 ff ff ff       	jmp    8010042a <cgaputc+0x64>

801004da <consputc>:
  if(panicked){
801004da:	83 3d 58 ef 10 80 00 	cmpl   $0x0,0x8010ef58
801004e1:	74 03                	je     801004e6 <consputc+0xc>
  asm volatile("cli");
801004e3:	fa                   	cli    
    for(;;)
801004e4:	eb fe                	jmp    801004e4 <consputc+0xa>
{
801004e6:	55                   	push   %ebp
801004e7:	89 e5                	mov    %esp,%ebp
801004e9:	53                   	push   %ebx
801004ea:	83 ec 04             	sub    $0x4,%esp
801004ed:	89 c3                	mov    %eax,%ebx
  if(c == BACKSPACE){
801004ef:	3d 00 01 00 00       	cmp    $0x100,%eax
801004f4:	74 18                	je     8010050e <consputc+0x34>
    uartputc(c);
801004f6:	83 ec 0c             	sub    $0xc,%esp
801004f9:	50                   	push   %eax
801004fa:	e8 1a 4d 00 00       	call   80105219 <uartputc>
801004ff:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
80100502:	89 d8                	mov    %ebx,%eax
80100504:	e8 bd fe ff ff       	call   801003c6 <cgaputc>
}
80100509:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010050c:	c9                   	leave  
8010050d:	c3                   	ret    
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010050e:	83 ec 0c             	sub    $0xc,%esp
80100511:	6a 08                	push   $0x8
80100513:	e8 01 4d 00 00       	call   80105219 <uartputc>
80100518:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010051f:	e8 f5 4c 00 00       	call   80105219 <uartputc>
80100524:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010052b:	e8 e9 4c 00 00       	call   80105219 <uartputc>
80100530:	83 c4 10             	add    $0x10,%esp
80100533:	eb cd                	jmp    80100502 <consputc+0x28>

80100535 <printint>:
{
80100535:	55                   	push   %ebp
80100536:	89 e5                	mov    %esp,%ebp
80100538:	57                   	push   %edi
80100539:	56                   	push   %esi
8010053a:	53                   	push   %ebx
8010053b:	83 ec 2c             	sub    $0x2c,%esp
8010053e:	89 d6                	mov    %edx,%esi
80100540:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
  if(sign && (sign = xx < 0))
80100543:	85 c9                	test   %ecx,%ecx
80100545:	74 0c                	je     80100553 <printint+0x1e>
80100547:	89 c7                	mov    %eax,%edi
80100549:	c1 ef 1f             	shr    $0x1f,%edi
8010054c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
8010054f:	85 c0                	test   %eax,%eax
80100551:	78 38                	js     8010058b <printint+0x56>
    x = xx;
80100553:	89 c1                	mov    %eax,%ecx
  i = 0;
80100555:	bb 00 00 00 00       	mov    $0x0,%ebx
    buf[i++] = digits[x % base];
8010055a:	89 c8                	mov    %ecx,%eax
8010055c:	ba 00 00 00 00       	mov    $0x0,%edx
80100561:	f7 f6                	div    %esi
80100563:	89 df                	mov    %ebx,%edi
80100565:	83 c3 01             	add    $0x1,%ebx
80100568:	0f b6 92 d0 68 10 80 	movzbl -0x7fef9730(%edx),%edx
8010056f:	88 54 3d d8          	mov    %dl,-0x28(%ebp,%edi,1)
  }while((x /= base) != 0);
80100573:	89 ca                	mov    %ecx,%edx
80100575:	89 c1                	mov    %eax,%ecx
80100577:	39 d6                	cmp    %edx,%esi
80100579:	76 df                	jbe    8010055a <printint+0x25>
  if(sign)
8010057b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
8010057f:	74 1a                	je     8010059b <printint+0x66>
    buf[i++] = '-';
80100581:	c6 44 1d d8 2d       	movb   $0x2d,-0x28(%ebp,%ebx,1)
80100586:	8d 5f 02             	lea    0x2(%edi),%ebx
80100589:	eb 10                	jmp    8010059b <printint+0x66>
    x = -xx;
8010058b:	f7 d8                	neg    %eax
8010058d:	89 c1                	mov    %eax,%ecx
8010058f:	eb c4                	jmp    80100555 <printint+0x20>
    consputc(buf[i]);
80100591:	0f be 44 1d d8       	movsbl -0x28(%ebp,%ebx,1),%eax
80100596:	e8 3f ff ff ff       	call   801004da <consputc>
  while(--i >= 0)
8010059b:	83 eb 01             	sub    $0x1,%ebx
8010059e:	79 f1                	jns    80100591 <printint+0x5c>
}
801005a0:	83 c4 2c             	add    $0x2c,%esp
801005a3:	5b                   	pop    %ebx
801005a4:	5e                   	pop    %esi
801005a5:	5f                   	pop    %edi
801005a6:	5d                   	pop    %ebp
801005a7:	c3                   	ret    

801005a8 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
801005a8:	55                   	push   %ebp
801005a9:	89 e5                	mov    %esp,%ebp
801005ab:	57                   	push   %edi
801005ac:	56                   	push   %esi
801005ad:	53                   	push   %ebx
801005ae:	83 ec 18             	sub    $0x18,%esp
801005b1:	8b 7d 0c             	mov    0xc(%ebp),%edi
801005b4:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  iunlock(ip);
801005b7:	ff 75 08             	push   0x8(%ebp)
801005ba:	e8 72 10 00 00       	call   80101631 <iunlock>
  acquire(&cons.lock);
801005bf:	c7 04 24 20 ef 10 80 	movl   $0x8010ef20,(%esp)
801005c6:	e8 b5 36 00 00       	call   80103c80 <acquire>
  for(i = 0; i < n; i++)
801005cb:	83 c4 10             	add    $0x10,%esp
801005ce:	bb 00 00 00 00       	mov    $0x0,%ebx
801005d3:	eb 0c                	jmp    801005e1 <consolewrite+0x39>
    consputc(buf[i] & 0xff);
801005d5:	0f b6 04 1f          	movzbl (%edi,%ebx,1),%eax
801005d9:	e8 fc fe ff ff       	call   801004da <consputc>
  for(i = 0; i < n; i++)
801005de:	83 c3 01             	add    $0x1,%ebx
801005e1:	39 f3                	cmp    %esi,%ebx
801005e3:	7c f0                	jl     801005d5 <consolewrite+0x2d>
  release(&cons.lock);
801005e5:	83 ec 0c             	sub    $0xc,%esp
801005e8:	68 20 ef 10 80       	push   $0x8010ef20
801005ed:	e8 f3 36 00 00       	call   80103ce5 <release>
  ilock(ip);
801005f2:	83 c4 04             	add    $0x4,%esp
801005f5:	ff 75 08             	push   0x8(%ebp)
801005f8:	e8 72 0f 00 00       	call   8010156f <ilock>

  return n;
}
801005fd:	89 f0                	mov    %esi,%eax
801005ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100602:	5b                   	pop    %ebx
80100603:	5e                   	pop    %esi
80100604:	5f                   	pop    %edi
80100605:	5d                   	pop    %ebp
80100606:	c3                   	ret    

80100607 <cprintf>:
{
80100607:	55                   	push   %ebp
80100608:	89 e5                	mov    %esp,%ebp
8010060a:	57                   	push   %edi
8010060b:	56                   	push   %esi
8010060c:	53                   	push   %ebx
8010060d:	83 ec 1c             	sub    $0x1c,%esp
  locking = cons.locking;
80100610:	a1 54 ef 10 80       	mov    0x8010ef54,%eax
80100615:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if(locking)
80100618:	85 c0                	test   %eax,%eax
8010061a:	75 10                	jne    8010062c <cprintf+0x25>
  if (fmt == 0)
8010061c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80100620:	74 1c                	je     8010063e <cprintf+0x37>
  argp = (uint*)(void*)(&fmt + 1);
80100622:	8d 7d 0c             	lea    0xc(%ebp),%edi
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100625:	be 00 00 00 00       	mov    $0x0,%esi
8010062a:	eb 27                	jmp    80100653 <cprintf+0x4c>
    acquire(&cons.lock);
8010062c:	83 ec 0c             	sub    $0xc,%esp
8010062f:	68 20 ef 10 80       	push   $0x8010ef20
80100634:	e8 47 36 00 00       	call   80103c80 <acquire>
80100639:	83 c4 10             	add    $0x10,%esp
8010063c:	eb de                	jmp    8010061c <cprintf+0x15>
    panic("null fmt");
8010063e:	83 ec 0c             	sub    $0xc,%esp
80100641:	68 bf 68 10 80       	push   $0x801068bf
80100646:	e8 fd fc ff ff       	call   80100348 <panic>
      consputc(c);
8010064b:	e8 8a fe ff ff       	call   801004da <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100650:	83 c6 01             	add    $0x1,%esi
80100653:	8b 55 08             	mov    0x8(%ebp),%edx
80100656:	0f b6 04 32          	movzbl (%edx,%esi,1),%eax
8010065a:	85 c0                	test   %eax,%eax
8010065c:	0f 84 b1 00 00 00    	je     80100713 <cprintf+0x10c>
    if(c != '%'){
80100662:	83 f8 25             	cmp    $0x25,%eax
80100665:	75 e4                	jne    8010064b <cprintf+0x44>
    c = fmt[++i] & 0xff;
80100667:	83 c6 01             	add    $0x1,%esi
8010066a:	0f b6 1c 32          	movzbl (%edx,%esi,1),%ebx
    if(c == 0)
8010066e:	85 db                	test   %ebx,%ebx
80100670:	0f 84 9d 00 00 00    	je     80100713 <cprintf+0x10c>
    switch(c){
80100676:	83 fb 70             	cmp    $0x70,%ebx
80100679:	74 2e                	je     801006a9 <cprintf+0xa2>
8010067b:	7f 22                	jg     8010069f <cprintf+0x98>
8010067d:	83 fb 25             	cmp    $0x25,%ebx
80100680:	74 6c                	je     801006ee <cprintf+0xe7>
80100682:	83 fb 64             	cmp    $0x64,%ebx
80100685:	75 76                	jne    801006fd <cprintf+0xf6>
      printint(*argp++, 10, 1);
80100687:	8d 5f 04             	lea    0x4(%edi),%ebx
8010068a:	8b 07                	mov    (%edi),%eax
8010068c:	b9 01 00 00 00       	mov    $0x1,%ecx
80100691:	ba 0a 00 00 00       	mov    $0xa,%edx
80100696:	e8 9a fe ff ff       	call   80100535 <printint>
8010069b:	89 df                	mov    %ebx,%edi
      break;
8010069d:	eb b1                	jmp    80100650 <cprintf+0x49>
    switch(c){
8010069f:	83 fb 73             	cmp    $0x73,%ebx
801006a2:	74 1d                	je     801006c1 <cprintf+0xba>
801006a4:	83 fb 78             	cmp    $0x78,%ebx
801006a7:	75 54                	jne    801006fd <cprintf+0xf6>
      printint(*argp++, 16, 0);
801006a9:	8d 5f 04             	lea    0x4(%edi),%ebx
801006ac:	8b 07                	mov    (%edi),%eax
801006ae:	b9 00 00 00 00       	mov    $0x0,%ecx
801006b3:	ba 10 00 00 00       	mov    $0x10,%edx
801006b8:	e8 78 fe ff ff       	call   80100535 <printint>
801006bd:	89 df                	mov    %ebx,%edi
      break;
801006bf:	eb 8f                	jmp    80100650 <cprintf+0x49>
      if((s = (char*)*argp++) == 0)
801006c1:	8d 47 04             	lea    0x4(%edi),%eax
801006c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801006c7:	8b 1f                	mov    (%edi),%ebx
801006c9:	85 db                	test   %ebx,%ebx
801006cb:	75 12                	jne    801006df <cprintf+0xd8>
        s = "(null)";
801006cd:	bb b8 68 10 80       	mov    $0x801068b8,%ebx
801006d2:	eb 0b                	jmp    801006df <cprintf+0xd8>
        consputc(*s);
801006d4:	0f be c0             	movsbl %al,%eax
801006d7:	e8 fe fd ff ff       	call   801004da <consputc>
      for(; *s; s++)
801006dc:	83 c3 01             	add    $0x1,%ebx
801006df:	0f b6 03             	movzbl (%ebx),%eax
801006e2:	84 c0                	test   %al,%al
801006e4:	75 ee                	jne    801006d4 <cprintf+0xcd>
      if((s = (char*)*argp++) == 0)
801006e6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801006e9:	e9 62 ff ff ff       	jmp    80100650 <cprintf+0x49>
      consputc('%');
801006ee:	b8 25 00 00 00       	mov    $0x25,%eax
801006f3:	e8 e2 fd ff ff       	call   801004da <consputc>
      break;
801006f8:	e9 53 ff ff ff       	jmp    80100650 <cprintf+0x49>
      consputc('%');
801006fd:	b8 25 00 00 00       	mov    $0x25,%eax
80100702:	e8 d3 fd ff ff       	call   801004da <consputc>
      consputc(c);
80100707:	89 d8                	mov    %ebx,%eax
80100709:	e8 cc fd ff ff       	call   801004da <consputc>
      break;
8010070e:	e9 3d ff ff ff       	jmp    80100650 <cprintf+0x49>
  if(locking)
80100713:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100717:	75 08                	jne    80100721 <cprintf+0x11a>
}
80100719:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010071c:	5b                   	pop    %ebx
8010071d:	5e                   	pop    %esi
8010071e:	5f                   	pop    %edi
8010071f:	5d                   	pop    %ebp
80100720:	c3                   	ret    
    release(&cons.lock);
80100721:	83 ec 0c             	sub    $0xc,%esp
80100724:	68 20 ef 10 80       	push   $0x8010ef20
80100729:	e8 b7 35 00 00       	call   80103ce5 <release>
8010072e:	83 c4 10             	add    $0x10,%esp
}
80100731:	eb e6                	jmp    80100719 <cprintf+0x112>

80100733 <consoleintr>:
{
80100733:	55                   	push   %ebp
80100734:	89 e5                	mov    %esp,%ebp
80100736:	57                   	push   %edi
80100737:	56                   	push   %esi
80100738:	53                   	push   %ebx
80100739:	83 ec 18             	sub    $0x18,%esp
8010073c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&cons.lock);
8010073f:	68 20 ef 10 80       	push   $0x8010ef20
80100744:	e8 37 35 00 00       	call   80103c80 <acquire>
  while((c = getc()) >= 0){
80100749:	83 c4 10             	add    $0x10,%esp
  int c, doprocdump = 0;
8010074c:	be 00 00 00 00       	mov    $0x0,%esi
  while((c = getc()) >= 0){
80100751:	eb 13                	jmp    80100766 <consoleintr+0x33>
    switch(c){
80100753:	83 ff 08             	cmp    $0x8,%edi
80100756:	0f 84 d9 00 00 00    	je     80100835 <consoleintr+0x102>
8010075c:	83 ff 10             	cmp    $0x10,%edi
8010075f:	75 25                	jne    80100786 <consoleintr+0x53>
80100761:	be 01 00 00 00       	mov    $0x1,%esi
  while((c = getc()) >= 0){
80100766:	ff d3                	call   *%ebx
80100768:	89 c7                	mov    %eax,%edi
8010076a:	85 c0                	test   %eax,%eax
8010076c:	0f 88 f5 00 00 00    	js     80100867 <consoleintr+0x134>
    switch(c){
80100772:	83 ff 15             	cmp    $0x15,%edi
80100775:	0f 84 93 00 00 00    	je     8010080e <consoleintr+0xdb>
8010077b:	7e d6                	jle    80100753 <consoleintr+0x20>
8010077d:	83 ff 7f             	cmp    $0x7f,%edi
80100780:	0f 84 af 00 00 00    	je     80100835 <consoleintr+0x102>
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100786:	85 ff                	test   %edi,%edi
80100788:	74 dc                	je     80100766 <consoleintr+0x33>
8010078a:	a1 08 ef 10 80       	mov    0x8010ef08,%eax
8010078f:	89 c2                	mov    %eax,%edx
80100791:	2b 15 00 ef 10 80    	sub    0x8010ef00,%edx
80100797:	83 fa 7f             	cmp    $0x7f,%edx
8010079a:	77 ca                	ja     80100766 <consoleintr+0x33>
        c = (c == '\r') ? '\n' : c;
8010079c:	83 ff 0d             	cmp    $0xd,%edi
8010079f:	0f 84 b8 00 00 00    	je     8010085d <consoleintr+0x12a>
        input.buf[input.e++ % INPUT_BUF] = c;
801007a5:	8d 50 01             	lea    0x1(%eax),%edx
801007a8:	89 15 08 ef 10 80    	mov    %edx,0x8010ef08
801007ae:	83 e0 7f             	and    $0x7f,%eax
801007b1:	89 f9                	mov    %edi,%ecx
801007b3:	88 88 80 ee 10 80    	mov    %cl,-0x7fef1180(%eax)
        consputc(c);
801007b9:	89 f8                	mov    %edi,%eax
801007bb:	e8 1a fd ff ff       	call   801004da <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801007c0:	83 ff 0a             	cmp    $0xa,%edi
801007c3:	0f 94 c0             	sete   %al
801007c6:	83 ff 04             	cmp    $0x4,%edi
801007c9:	0f 94 c2             	sete   %dl
801007cc:	08 d0                	or     %dl,%al
801007ce:	75 10                	jne    801007e0 <consoleintr+0xad>
801007d0:	a1 00 ef 10 80       	mov    0x8010ef00,%eax
801007d5:	83 e8 80             	sub    $0xffffff80,%eax
801007d8:	39 05 08 ef 10 80    	cmp    %eax,0x8010ef08
801007de:	75 86                	jne    80100766 <consoleintr+0x33>
          input.w = input.e;
801007e0:	a1 08 ef 10 80       	mov    0x8010ef08,%eax
801007e5:	a3 04 ef 10 80       	mov    %eax,0x8010ef04
          wakeup(&input.r);
801007ea:	83 ec 0c             	sub    $0xc,%esp
801007ed:	68 00 ef 10 80       	push   $0x8010ef00
801007f2:	e8 ee 30 00 00       	call   801038e5 <wakeup>
801007f7:	83 c4 10             	add    $0x10,%esp
801007fa:	e9 67 ff ff ff       	jmp    80100766 <consoleintr+0x33>
        input.e--;
801007ff:	a3 08 ef 10 80       	mov    %eax,0x8010ef08
        consputc(BACKSPACE);
80100804:	b8 00 01 00 00       	mov    $0x100,%eax
80100809:	e8 cc fc ff ff       	call   801004da <consputc>
      while(input.e != input.w &&
8010080e:	a1 08 ef 10 80       	mov    0x8010ef08,%eax
80100813:	3b 05 04 ef 10 80    	cmp    0x8010ef04,%eax
80100819:	0f 84 47 ff ff ff    	je     80100766 <consoleintr+0x33>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010081f:	83 e8 01             	sub    $0x1,%eax
80100822:	89 c2                	mov    %eax,%edx
80100824:	83 e2 7f             	and    $0x7f,%edx
      while(input.e != input.w &&
80100827:	80 ba 80 ee 10 80 0a 	cmpb   $0xa,-0x7fef1180(%edx)
8010082e:	75 cf                	jne    801007ff <consoleintr+0xcc>
80100830:	e9 31 ff ff ff       	jmp    80100766 <consoleintr+0x33>
      if(input.e != input.w){
80100835:	a1 08 ef 10 80       	mov    0x8010ef08,%eax
8010083a:	3b 05 04 ef 10 80    	cmp    0x8010ef04,%eax
80100840:	0f 84 20 ff ff ff    	je     80100766 <consoleintr+0x33>
        input.e--;
80100846:	83 e8 01             	sub    $0x1,%eax
80100849:	a3 08 ef 10 80       	mov    %eax,0x8010ef08
        consputc(BACKSPACE);
8010084e:	b8 00 01 00 00       	mov    $0x100,%eax
80100853:	e8 82 fc ff ff       	call   801004da <consputc>
80100858:	e9 09 ff ff ff       	jmp    80100766 <consoleintr+0x33>
        c = (c == '\r') ? '\n' : c;
8010085d:	bf 0a 00 00 00       	mov    $0xa,%edi
80100862:	e9 3e ff ff ff       	jmp    801007a5 <consoleintr+0x72>
  release(&cons.lock);
80100867:	83 ec 0c             	sub    $0xc,%esp
8010086a:	68 20 ef 10 80       	push   $0x8010ef20
8010086f:	e8 71 34 00 00       	call   80103ce5 <release>
  if(doprocdump) {
80100874:	83 c4 10             	add    $0x10,%esp
80100877:	85 f6                	test   %esi,%esi
80100879:	75 08                	jne    80100883 <consoleintr+0x150>
}
8010087b:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010087e:	5b                   	pop    %ebx
8010087f:	5e                   	pop    %esi
80100880:	5f                   	pop    %edi
80100881:	5d                   	pop    %ebp
80100882:	c3                   	ret    
    procdump();  // now call procdump() wo. cons.lock held
80100883:	e8 fc 30 00 00       	call   80103984 <procdump>
}
80100888:	eb f1                	jmp    8010087b <consoleintr+0x148>

8010088a <consoleinit>:

void
consoleinit(void)
{
8010088a:	55                   	push   %ebp
8010088b:	89 e5                	mov    %esp,%ebp
8010088d:	83 ec 10             	sub    $0x10,%esp
  initlock(&cons.lock, "console");
80100890:	68 c8 68 10 80       	push   $0x801068c8
80100895:	68 20 ef 10 80       	push   $0x8010ef20
8010089a:	e8 a5 32 00 00       	call   80103b44 <initlock>

  devsw[CONSOLE].write = consolewrite;
8010089f:	c7 05 0c f9 10 80 a8 	movl   $0x801005a8,0x8010f90c
801008a6:	05 10 80 
  devsw[CONSOLE].read = consoleread;
801008a9:	c7 05 08 f9 10 80 68 	movl   $0x80100268,0x8010f908
801008b0:	02 10 80 
  cons.locking = 1;
801008b3:	c7 05 54 ef 10 80 01 	movl   $0x1,0x8010ef54
801008ba:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
801008bd:	83 c4 08             	add    $0x8,%esp
801008c0:	6a 00                	push   $0x0
801008c2:	6a 01                	push   $0x1
801008c4:	e8 98 16 00 00       	call   80101f61 <ioapicenable>
}
801008c9:	83 c4 10             	add    $0x10,%esp
801008cc:	c9                   	leave  
801008cd:	c3                   	ret    

801008ce <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
801008ce:	55                   	push   %ebp
801008cf:	89 e5                	mov    %esp,%ebp
801008d1:	57                   	push   %edi
801008d2:	56                   	push   %esi
801008d3:	53                   	push   %ebx
801008d4:	81 ec 0c 01 00 00    	sub    $0x10c,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
801008da:	e8 3c 29 00 00       	call   8010321b <myproc>
801008df:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)

  begin_op();
801008e5:	e8 94 1e 00 00       	call   8010277e <begin_op>

  if((ip = namei(path)) == 0){
801008ea:	83 ec 0c             	sub    $0xc,%esp
801008ed:	ff 75 08             	push   0x8(%ebp)
801008f0:	e8 d8 12 00 00       	call   80101bcd <namei>
801008f5:	83 c4 10             	add    $0x10,%esp
801008f8:	85 c0                	test   %eax,%eax
801008fa:	74 56                	je     80100952 <exec+0x84>
801008fc:	89 c3                	mov    %eax,%ebx
    end_op();
    cprintf("exec: fail\n");
    return -1;
  }
  ilock(ip);
801008fe:	83 ec 0c             	sub    $0xc,%esp
80100901:	50                   	push   %eax
80100902:	e8 68 0c 00 00       	call   8010156f <ilock>
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100907:	6a 34                	push   $0x34
80100909:	6a 00                	push   $0x0
8010090b:	8d 85 24 ff ff ff    	lea    -0xdc(%ebp),%eax
80100911:	50                   	push   %eax
80100912:	53                   	push   %ebx
80100913:	e8 49 0e 00 00       	call   80101761 <readi>
80100918:	83 c4 20             	add    $0x20,%esp
8010091b:	83 f8 34             	cmp    $0x34,%eax
8010091e:	75 0c                	jne    8010092c <exec+0x5e>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100920:	81 bd 24 ff ff ff 7f 	cmpl   $0x464c457f,-0xdc(%ebp)
80100927:	45 4c 46 
8010092a:	74 42                	je     8010096e <exec+0xa0>
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
8010092c:	85 db                	test   %ebx,%ebx
8010092e:	0f 84 c5 02 00 00    	je     80100bf9 <exec+0x32b>
    iunlockput(ip);
80100934:	83 ec 0c             	sub    $0xc,%esp
80100937:	53                   	push   %ebx
80100938:	e8 d9 0d 00 00       	call   80101716 <iunlockput>
    end_op();
8010093d:	e8 b6 1e 00 00       	call   801027f8 <end_op>
80100942:	83 c4 10             	add    $0x10,%esp
  }
  return -1;
80100945:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010094a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010094d:	5b                   	pop    %ebx
8010094e:	5e                   	pop    %esi
8010094f:	5f                   	pop    %edi
80100950:	5d                   	pop    %ebp
80100951:	c3                   	ret    
    end_op();
80100952:	e8 a1 1e 00 00       	call   801027f8 <end_op>
    cprintf("exec: fail\n");
80100957:	83 ec 0c             	sub    $0xc,%esp
8010095a:	68 e1 68 10 80       	push   $0x801068e1
8010095f:	e8 a3 fc ff ff       	call   80100607 <cprintf>
    return -1;
80100964:	83 c4 10             	add    $0x10,%esp
80100967:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010096c:	eb dc                	jmp    8010094a <exec+0x7c>
  if((pgdir = setupkvm()) == 0)
8010096e:	e8 ce 5b 00 00       	call   80106541 <setupkvm>
80100973:	89 85 f0 fe ff ff    	mov    %eax,-0x110(%ebp)
80100979:	85 c0                	test   %eax,%eax
8010097b:	0f 84 09 01 00 00    	je     80100a8a <exec+0x1bc>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100981:	8b 85 40 ff ff ff    	mov    -0xc0(%ebp),%eax
  sz = 0;//PGSIZE;
80100987:	bf 00 00 00 00       	mov    $0x0,%edi
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
8010098c:	be 00 00 00 00       	mov    $0x0,%esi
80100991:	eb 0c                	jmp    8010099f <exec+0xd1>
80100993:	83 c6 01             	add    $0x1,%esi
80100996:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
8010099c:	83 c0 20             	add    $0x20,%eax
8010099f:	0f b7 95 50 ff ff ff 	movzwl -0xb0(%ebp),%edx
801009a6:	39 f2                	cmp    %esi,%edx
801009a8:	0f 8e 98 00 00 00    	jle    80100a46 <exec+0x178>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
801009ae:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
801009b4:	6a 20                	push   $0x20
801009b6:	50                   	push   %eax
801009b7:	8d 85 04 ff ff ff    	lea    -0xfc(%ebp),%eax
801009bd:	50                   	push   %eax
801009be:	53                   	push   %ebx
801009bf:	e8 9d 0d 00 00       	call   80101761 <readi>
801009c4:	83 c4 10             	add    $0x10,%esp
801009c7:	83 f8 20             	cmp    $0x20,%eax
801009ca:	0f 85 ba 00 00 00    	jne    80100a8a <exec+0x1bc>
    if(ph.type != ELF_PROG_LOAD)
801009d0:	83 bd 04 ff ff ff 01 	cmpl   $0x1,-0xfc(%ebp)
801009d7:	75 ba                	jne    80100993 <exec+0xc5>
    if(ph.memsz < ph.filesz)
801009d9:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
801009df:	3b 85 14 ff ff ff    	cmp    -0xec(%ebp),%eax
801009e5:	0f 82 9f 00 00 00    	jb     80100a8a <exec+0x1bc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
801009eb:	03 85 0c ff ff ff    	add    -0xf4(%ebp),%eax
801009f1:	0f 82 93 00 00 00    	jb     80100a8a <exec+0x1bc>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
801009f7:	83 ec 04             	sub    $0x4,%esp
801009fa:	50                   	push   %eax
801009fb:	57                   	push   %edi
801009fc:	ff b5 f0 fe ff ff    	push   -0x110(%ebp)
80100a02:	e8 e0 59 00 00       	call   801063e7 <allocuvm>
80100a07:	89 c7                	mov    %eax,%edi
80100a09:	83 c4 10             	add    $0x10,%esp
80100a0c:	85 c0                	test   %eax,%eax
80100a0e:	74 7a                	je     80100a8a <exec+0x1bc>
    if(ph.vaddr % PGSIZE != 0)
80100a10:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100a16:	a9 ff 0f 00 00       	test   $0xfff,%eax
80100a1b:	75 6d                	jne    80100a8a <exec+0x1bc>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100a1d:	83 ec 0c             	sub    $0xc,%esp
80100a20:	ff b5 14 ff ff ff    	push   -0xec(%ebp)
80100a26:	ff b5 08 ff ff ff    	push   -0xf8(%ebp)
80100a2c:	53                   	push   %ebx
80100a2d:	50                   	push   %eax
80100a2e:	ff b5 f0 fe ff ff    	push   -0x110(%ebp)
80100a34:	e8 81 58 00 00       	call   801062ba <loaduvm>
80100a39:	83 c4 20             	add    $0x20,%esp
80100a3c:	85 c0                	test   %eax,%eax
80100a3e:	0f 89 4f ff ff ff    	jns    80100993 <exec+0xc5>
80100a44:	eb 44                	jmp    80100a8a <exec+0x1bc>
  iunlockput(ip);
80100a46:	83 ec 0c             	sub    $0xc,%esp
80100a49:	53                   	push   %ebx
80100a4a:	e8 c7 0c 00 00       	call   80101716 <iunlockput>
  end_op();
80100a4f:	e8 a4 1d 00 00       	call   801027f8 <end_op>
  sz = PGROUNDUP(sz);
80100a54:	8d 87 ff 0f 00 00    	lea    0xfff(%edi),%eax
80100a5a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100a5f:	83 c4 0c             	add    $0xc,%esp
80100a62:	8d 90 00 20 00 00    	lea    0x2000(%eax),%edx
80100a68:	52                   	push   %edx
80100a69:	50                   	push   %eax
80100a6a:	8b bd f0 fe ff ff    	mov    -0x110(%ebp),%edi
80100a70:	57                   	push   %edi
80100a71:	e8 71 59 00 00       	call   801063e7 <allocuvm>
80100a76:	89 c6                	mov    %eax,%esi
80100a78:	89 85 f4 fe ff ff    	mov    %eax,-0x10c(%ebp)
80100a7e:	83 c4 10             	add    $0x10,%esp
80100a81:	85 c0                	test   %eax,%eax
80100a83:	75 24                	jne    80100aa9 <exec+0x1db>
  ip = 0;
80100a85:	bb 00 00 00 00       	mov    $0x0,%ebx
  if(pgdir)
80100a8a:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100a90:	85 c0                	test   %eax,%eax
80100a92:	0f 84 94 fe ff ff    	je     8010092c <exec+0x5e>
    freevm(pgdir);
80100a98:	83 ec 0c             	sub    $0xc,%esp
80100a9b:	50                   	push   %eax
80100a9c:	e8 30 5a 00 00       	call   801064d1 <freevm>
80100aa1:	83 c4 10             	add    $0x10,%esp
80100aa4:	e9 83 fe ff ff       	jmp    8010092c <exec+0x5e>
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100aa9:	8d 80 00 e0 ff ff    	lea    -0x2000(%eax),%eax
80100aaf:	83 ec 08             	sub    $0x8,%esp
80100ab2:	50                   	push   %eax
80100ab3:	57                   	push   %edi
80100ab4:	e8 0d 5b 00 00       	call   801065c6 <clearpteu>
  for(argc = 0; argv[argc]; argc++) {
80100ab9:	83 c4 10             	add    $0x10,%esp
80100abc:	bf 00 00 00 00       	mov    $0x0,%edi
80100ac1:	eb 0a                	jmp    80100acd <exec+0x1ff>
    ustack[3+argc] = sp;
80100ac3:	89 b4 bd 64 ff ff ff 	mov    %esi,-0x9c(%ebp,%edi,4)
  for(argc = 0; argv[argc]; argc++) {
80100aca:	83 c7 01             	add    $0x1,%edi
80100acd:	8b 45 0c             	mov    0xc(%ebp),%eax
80100ad0:	8d 1c b8             	lea    (%eax,%edi,4),%ebx
80100ad3:	8b 03                	mov    (%ebx),%eax
80100ad5:	85 c0                	test   %eax,%eax
80100ad7:	74 47                	je     80100b20 <exec+0x252>
    if(argc >= MAXARG)
80100ad9:	83 ff 1f             	cmp    $0x1f,%edi
80100adc:	0f 87 0d 01 00 00    	ja     80100bef <exec+0x321>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100ae2:	83 ec 0c             	sub    $0xc,%esp
80100ae5:	50                   	push   %eax
80100ae6:	e8 ea 33 00 00       	call   80103ed5 <strlen>
80100aeb:	29 c6                	sub    %eax,%esi
80100aed:	83 ee 01             	sub    $0x1,%esi
80100af0:	83 e6 fc             	and    $0xfffffffc,%esi
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100af3:	83 c4 04             	add    $0x4,%esp
80100af6:	ff 33                	push   (%ebx)
80100af8:	e8 d8 33 00 00       	call   80103ed5 <strlen>
80100afd:	83 c0 01             	add    $0x1,%eax
80100b00:	50                   	push   %eax
80100b01:	ff 33                	push   (%ebx)
80100b03:	56                   	push   %esi
80100b04:	ff b5 f0 fe ff ff    	push   -0x110(%ebp)
80100b0a:	e8 d3 5c 00 00       	call   801067e2 <copyout>
80100b0f:	83 c4 20             	add    $0x20,%esp
80100b12:	85 c0                	test   %eax,%eax
80100b14:	79 ad                	jns    80100ac3 <exec+0x1f5>
  ip = 0;
80100b16:	bb 00 00 00 00       	mov    $0x0,%ebx
80100b1b:	e9 6a ff ff ff       	jmp    80100a8a <exec+0x1bc>
  ustack[3+argc] = 0;
80100b20:	89 f1                	mov    %esi,%ecx
80100b22:	89 c3                	mov    %eax,%ebx
80100b24:	c7 84 bd 64 ff ff ff 	movl   $0x0,-0x9c(%ebp,%edi,4)
80100b2b:	00 00 00 00 
  ustack[0] = 0xffffffff;  // fake return PC
80100b2f:	c7 85 58 ff ff ff ff 	movl   $0xffffffff,-0xa8(%ebp)
80100b36:	ff ff ff 
  ustack[1] = argc;
80100b39:	89 bd 5c ff ff ff    	mov    %edi,-0xa4(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100b3f:	8d 14 bd 04 00 00 00 	lea    0x4(,%edi,4),%edx
80100b46:	89 f0                	mov    %esi,%eax
80100b48:	29 d0                	sub    %edx,%eax
80100b4a:	89 85 60 ff ff ff    	mov    %eax,-0xa0(%ebp)
  sp -= (3+argc+1) * 4;
80100b50:	8d 04 bd 10 00 00 00 	lea    0x10(,%edi,4),%eax
80100b57:	29 c1                	sub    %eax,%ecx
80100b59:	89 ce                	mov    %ecx,%esi
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100b5b:	50                   	push   %eax
80100b5c:	8d 85 58 ff ff ff    	lea    -0xa8(%ebp),%eax
80100b62:	50                   	push   %eax
80100b63:	51                   	push   %ecx
80100b64:	ff b5 f0 fe ff ff    	push   -0x110(%ebp)
80100b6a:	e8 73 5c 00 00       	call   801067e2 <copyout>
80100b6f:	83 c4 10             	add    $0x10,%esp
80100b72:	85 c0                	test   %eax,%eax
80100b74:	0f 88 10 ff ff ff    	js     80100a8a <exec+0x1bc>
  for(last=s=path; *s; s++)
80100b7a:	8b 55 08             	mov    0x8(%ebp),%edx
80100b7d:	89 d0                	mov    %edx,%eax
80100b7f:	eb 03                	jmp    80100b84 <exec+0x2b6>
80100b81:	83 c0 01             	add    $0x1,%eax
80100b84:	0f b6 08             	movzbl (%eax),%ecx
80100b87:	84 c9                	test   %cl,%cl
80100b89:	74 0a                	je     80100b95 <exec+0x2c7>
    if(*s == '/')
80100b8b:	80 f9 2f             	cmp    $0x2f,%cl
80100b8e:	75 f1                	jne    80100b81 <exec+0x2b3>
      last = s+1;
80100b90:	8d 50 01             	lea    0x1(%eax),%edx
80100b93:	eb ec                	jmp    80100b81 <exec+0x2b3>
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100b95:	8b bd ec fe ff ff    	mov    -0x114(%ebp),%edi
80100b9b:	89 f8                	mov    %edi,%eax
80100b9d:	83 c0 6c             	add    $0x6c,%eax
80100ba0:	83 ec 04             	sub    $0x4,%esp
80100ba3:	6a 10                	push   $0x10
80100ba5:	52                   	push   %edx
80100ba6:	50                   	push   %eax
80100ba7:	e8 ec 32 00 00       	call   80103e98 <safestrcpy>
  oldpgdir = curproc->pgdir;
80100bac:	8b 5f 04             	mov    0x4(%edi),%ebx
  curproc->pgdir = pgdir;
80100baf:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100bb5:	89 4f 04             	mov    %ecx,0x4(%edi)
  curproc->sz = sz;
80100bb8:	8b 8d f4 fe ff ff    	mov    -0x10c(%ebp),%ecx
80100bbe:	89 0f                	mov    %ecx,(%edi)
  curproc->tf->eip = elf.entry;  // main
80100bc0:	8b 47 18             	mov    0x18(%edi),%eax
80100bc3:	8b 95 3c ff ff ff    	mov    -0xc4(%ebp),%edx
80100bc9:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100bcc:	8b 47 18             	mov    0x18(%edi),%eax
80100bcf:	89 70 44             	mov    %esi,0x44(%eax)
  switchuvm(curproc);
80100bd2:	89 3c 24             	mov    %edi,(%esp)
80100bd5:	e8 17 55 00 00       	call   801060f1 <switchuvm>
  freevm(oldpgdir);
80100bda:	89 1c 24             	mov    %ebx,(%esp)
80100bdd:	e8 ef 58 00 00       	call   801064d1 <freevm>
  return 0;
80100be2:	83 c4 10             	add    $0x10,%esp
80100be5:	b8 00 00 00 00       	mov    $0x0,%eax
80100bea:	e9 5b fd ff ff       	jmp    8010094a <exec+0x7c>
  ip = 0;
80100bef:	bb 00 00 00 00       	mov    $0x0,%ebx
80100bf4:	e9 91 fe ff ff       	jmp    80100a8a <exec+0x1bc>
  return -1;
80100bf9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100bfe:	e9 47 fd ff ff       	jmp    8010094a <exec+0x7c>

80100c03 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100c03:	55                   	push   %ebp
80100c04:	89 e5                	mov    %esp,%ebp
80100c06:	83 ec 10             	sub    $0x10,%esp
  initlock(&ftable.lock, "ftable");
80100c09:	68 ed 68 10 80       	push   $0x801068ed
80100c0e:	68 60 ef 10 80       	push   $0x8010ef60
80100c13:	e8 2c 2f 00 00       	call   80103b44 <initlock>
}
80100c18:	83 c4 10             	add    $0x10,%esp
80100c1b:	c9                   	leave  
80100c1c:	c3                   	ret    

80100c1d <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100c1d:	55                   	push   %ebp
80100c1e:	89 e5                	mov    %esp,%ebp
80100c20:	53                   	push   %ebx
80100c21:	83 ec 10             	sub    $0x10,%esp
  struct file *f;

  acquire(&ftable.lock);
80100c24:	68 60 ef 10 80       	push   $0x8010ef60
80100c29:	e8 52 30 00 00       	call   80103c80 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c2e:	83 c4 10             	add    $0x10,%esp
80100c31:	bb 94 ef 10 80       	mov    $0x8010ef94,%ebx
80100c36:	81 fb f4 f8 10 80    	cmp    $0x8010f8f4,%ebx
80100c3c:	73 29                	jae    80100c67 <filealloc+0x4a>
    if(f->ref == 0){
80100c3e:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80100c42:	74 05                	je     80100c49 <filealloc+0x2c>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100c44:	83 c3 18             	add    $0x18,%ebx
80100c47:	eb ed                	jmp    80100c36 <filealloc+0x19>
      f->ref = 1;
80100c49:	c7 43 04 01 00 00 00 	movl   $0x1,0x4(%ebx)
      release(&ftable.lock);
80100c50:	83 ec 0c             	sub    $0xc,%esp
80100c53:	68 60 ef 10 80       	push   $0x8010ef60
80100c58:	e8 88 30 00 00       	call   80103ce5 <release>
      return f;
80100c5d:	83 c4 10             	add    $0x10,%esp
    }
  }
  release(&ftable.lock);
  return 0;
}
80100c60:	89 d8                	mov    %ebx,%eax
80100c62:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100c65:	c9                   	leave  
80100c66:	c3                   	ret    
  release(&ftable.lock);
80100c67:	83 ec 0c             	sub    $0xc,%esp
80100c6a:	68 60 ef 10 80       	push   $0x8010ef60
80100c6f:	e8 71 30 00 00       	call   80103ce5 <release>
  return 0;
80100c74:	83 c4 10             	add    $0x10,%esp
80100c77:	bb 00 00 00 00       	mov    $0x0,%ebx
80100c7c:	eb e2                	jmp    80100c60 <filealloc+0x43>

80100c7e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100c7e:	55                   	push   %ebp
80100c7f:	89 e5                	mov    %esp,%ebp
80100c81:	53                   	push   %ebx
80100c82:	83 ec 10             	sub    $0x10,%esp
80100c85:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&ftable.lock);
80100c88:	68 60 ef 10 80       	push   $0x8010ef60
80100c8d:	e8 ee 2f 00 00       	call   80103c80 <acquire>
  if(f->ref < 1)
80100c92:	8b 43 04             	mov    0x4(%ebx),%eax
80100c95:	83 c4 10             	add    $0x10,%esp
80100c98:	85 c0                	test   %eax,%eax
80100c9a:	7e 1a                	jle    80100cb6 <filedup+0x38>
    panic("filedup");
  f->ref++;
80100c9c:	83 c0 01             	add    $0x1,%eax
80100c9f:	89 43 04             	mov    %eax,0x4(%ebx)
  release(&ftable.lock);
80100ca2:	83 ec 0c             	sub    $0xc,%esp
80100ca5:	68 60 ef 10 80       	push   $0x8010ef60
80100caa:	e8 36 30 00 00       	call   80103ce5 <release>
  return f;
}
80100caf:	89 d8                	mov    %ebx,%eax
80100cb1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100cb4:	c9                   	leave  
80100cb5:	c3                   	ret    
    panic("filedup");
80100cb6:	83 ec 0c             	sub    $0xc,%esp
80100cb9:	68 f4 68 10 80       	push   $0x801068f4
80100cbe:	e8 85 f6 ff ff       	call   80100348 <panic>

80100cc3 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80100cc3:	55                   	push   %ebp
80100cc4:	89 e5                	mov    %esp,%ebp
80100cc6:	53                   	push   %ebx
80100cc7:	83 ec 30             	sub    $0x30,%esp
80100cca:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct file ff;

  acquire(&ftable.lock);
80100ccd:	68 60 ef 10 80       	push   $0x8010ef60
80100cd2:	e8 a9 2f 00 00       	call   80103c80 <acquire>
  if(f->ref < 1)
80100cd7:	8b 43 04             	mov    0x4(%ebx),%eax
80100cda:	83 c4 10             	add    $0x10,%esp
80100cdd:	85 c0                	test   %eax,%eax
80100cdf:	7e 71                	jle    80100d52 <fileclose+0x8f>
    panic("fileclose");
  if(--f->ref > 0){
80100ce1:	83 e8 01             	sub    $0x1,%eax
80100ce4:	89 43 04             	mov    %eax,0x4(%ebx)
80100ce7:	85 c0                	test   %eax,%eax
80100ce9:	7f 74                	jg     80100d5f <fileclose+0x9c>
    release(&ftable.lock);
    return;
  }
  ff = *f;
80100ceb:	8b 03                	mov    (%ebx),%eax
80100ced:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cf0:	8b 43 04             	mov    0x4(%ebx),%eax
80100cf3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80100cf6:	8b 43 08             	mov    0x8(%ebx),%eax
80100cf9:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100cfc:	8b 43 0c             	mov    0xc(%ebx),%eax
80100cff:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100d02:	8b 43 10             	mov    0x10(%ebx),%eax
80100d05:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100d08:	8b 43 14             	mov    0x14(%ebx),%eax
80100d0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80100d0e:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
  f->type = FD_NONE;
80100d15:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  release(&ftable.lock);
80100d1b:	83 ec 0c             	sub    $0xc,%esp
80100d1e:	68 60 ef 10 80       	push   $0x8010ef60
80100d23:	e8 bd 2f 00 00       	call   80103ce5 <release>

  if(ff.type == FD_PIPE)
80100d28:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d2b:	83 c4 10             	add    $0x10,%esp
80100d2e:	83 f8 01             	cmp    $0x1,%eax
80100d31:	74 41                	je     80100d74 <fileclose+0xb1>
    pipeclose(ff.pipe, ff.writable);
  else if(ff.type == FD_INODE){
80100d33:	83 f8 02             	cmp    $0x2,%eax
80100d36:	75 37                	jne    80100d6f <fileclose+0xac>
    begin_op();
80100d38:	e8 41 1a 00 00       	call   8010277e <begin_op>
    iput(ff.ip);
80100d3d:	83 ec 0c             	sub    $0xc,%esp
80100d40:	ff 75 f0             	push   -0x10(%ebp)
80100d43:	e8 2e 09 00 00       	call   80101676 <iput>
    end_op();
80100d48:	e8 ab 1a 00 00       	call   801027f8 <end_op>
80100d4d:	83 c4 10             	add    $0x10,%esp
80100d50:	eb 1d                	jmp    80100d6f <fileclose+0xac>
    panic("fileclose");
80100d52:	83 ec 0c             	sub    $0xc,%esp
80100d55:	68 fc 68 10 80       	push   $0x801068fc
80100d5a:	e8 e9 f5 ff ff       	call   80100348 <panic>
    release(&ftable.lock);
80100d5f:	83 ec 0c             	sub    $0xc,%esp
80100d62:	68 60 ef 10 80       	push   $0x8010ef60
80100d67:	e8 79 2f 00 00       	call   80103ce5 <release>
    return;
80100d6c:	83 c4 10             	add    $0x10,%esp
  }
}
80100d6f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100d72:	c9                   	leave  
80100d73:	c3                   	ret    
    pipeclose(ff.pipe, ff.writable);
80100d74:	83 ec 08             	sub    $0x8,%esp
80100d77:	0f be 45 e9          	movsbl -0x17(%ebp),%eax
80100d7b:	50                   	push   %eax
80100d7c:	ff 75 ec             	push   -0x14(%ebp)
80100d7f:	e8 6d 20 00 00       	call   80102df1 <pipeclose>
80100d84:	83 c4 10             	add    $0x10,%esp
80100d87:	eb e6                	jmp    80100d6f <fileclose+0xac>

80100d89 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80100d89:	55                   	push   %ebp
80100d8a:	89 e5                	mov    %esp,%ebp
80100d8c:	53                   	push   %ebx
80100d8d:	83 ec 04             	sub    $0x4,%esp
80100d90:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(f->type == FD_INODE){
80100d93:	83 3b 02             	cmpl   $0x2,(%ebx)
80100d96:	75 31                	jne    80100dc9 <filestat+0x40>
    ilock(f->ip);
80100d98:	83 ec 0c             	sub    $0xc,%esp
80100d9b:	ff 73 10             	push   0x10(%ebx)
80100d9e:	e8 cc 07 00 00       	call   8010156f <ilock>
    stati(f->ip, st);
80100da3:	83 c4 08             	add    $0x8,%esp
80100da6:	ff 75 0c             	push   0xc(%ebp)
80100da9:	ff 73 10             	push   0x10(%ebx)
80100dac:	e8 85 09 00 00       	call   80101736 <stati>
    iunlock(f->ip);
80100db1:	83 c4 04             	add    $0x4,%esp
80100db4:	ff 73 10             	push   0x10(%ebx)
80100db7:	e8 75 08 00 00       	call   80101631 <iunlock>
    return 0;
80100dbc:	83 c4 10             	add    $0x10,%esp
80100dbf:	b8 00 00 00 00       	mov    $0x0,%eax
  }
  return -1;
}
80100dc4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100dc7:	c9                   	leave  
80100dc8:	c3                   	ret    
  return -1;
80100dc9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100dce:	eb f4                	jmp    80100dc4 <filestat+0x3b>

80100dd0 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80100dd0:	55                   	push   %ebp
80100dd1:	89 e5                	mov    %esp,%ebp
80100dd3:	56                   	push   %esi
80100dd4:	53                   	push   %ebx
80100dd5:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;

  if(f->readable == 0)
80100dd8:	80 7b 08 00          	cmpb   $0x0,0x8(%ebx)
80100ddc:	74 70                	je     80100e4e <fileread+0x7e>
    return -1;
  if(f->type == FD_PIPE)
80100dde:	8b 03                	mov    (%ebx),%eax
80100de0:	83 f8 01             	cmp    $0x1,%eax
80100de3:	74 44                	je     80100e29 <fileread+0x59>
    return piperead(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100de5:	83 f8 02             	cmp    $0x2,%eax
80100de8:	75 57                	jne    80100e41 <fileread+0x71>
    ilock(f->ip);
80100dea:	83 ec 0c             	sub    $0xc,%esp
80100ded:	ff 73 10             	push   0x10(%ebx)
80100df0:	e8 7a 07 00 00       	call   8010156f <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80100df5:	ff 75 10             	push   0x10(%ebp)
80100df8:	ff 73 14             	push   0x14(%ebx)
80100dfb:	ff 75 0c             	push   0xc(%ebp)
80100dfe:	ff 73 10             	push   0x10(%ebx)
80100e01:	e8 5b 09 00 00       	call   80101761 <readi>
80100e06:	89 c6                	mov    %eax,%esi
80100e08:	83 c4 20             	add    $0x20,%esp
80100e0b:	85 c0                	test   %eax,%eax
80100e0d:	7e 03                	jle    80100e12 <fileread+0x42>
      f->off += r;
80100e0f:	01 43 14             	add    %eax,0x14(%ebx)
    iunlock(f->ip);
80100e12:	83 ec 0c             	sub    $0xc,%esp
80100e15:	ff 73 10             	push   0x10(%ebx)
80100e18:	e8 14 08 00 00       	call   80101631 <iunlock>
    return r;
80100e1d:	83 c4 10             	add    $0x10,%esp
  }
  panic("fileread");
}
80100e20:	89 f0                	mov    %esi,%eax
80100e22:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100e25:	5b                   	pop    %ebx
80100e26:	5e                   	pop    %esi
80100e27:	5d                   	pop    %ebp
80100e28:	c3                   	ret    
    return piperead(f->pipe, addr, n);
80100e29:	83 ec 04             	sub    $0x4,%esp
80100e2c:	ff 75 10             	push   0x10(%ebp)
80100e2f:	ff 75 0c             	push   0xc(%ebp)
80100e32:	ff 73 0c             	push   0xc(%ebx)
80100e35:	e8 08 21 00 00       	call   80102f42 <piperead>
80100e3a:	89 c6                	mov    %eax,%esi
80100e3c:	83 c4 10             	add    $0x10,%esp
80100e3f:	eb df                	jmp    80100e20 <fileread+0x50>
  panic("fileread");
80100e41:	83 ec 0c             	sub    $0xc,%esp
80100e44:	68 06 69 10 80       	push   $0x80106906
80100e49:	e8 fa f4 ff ff       	call   80100348 <panic>
    return -1;
80100e4e:	be ff ff ff ff       	mov    $0xffffffff,%esi
80100e53:	eb cb                	jmp    80100e20 <fileread+0x50>

80100e55 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
80100e55:	55                   	push   %ebp
80100e56:	89 e5                	mov    %esp,%ebp
80100e58:	57                   	push   %edi
80100e59:	56                   	push   %esi
80100e5a:	53                   	push   %ebx
80100e5b:	83 ec 1c             	sub    $0x1c,%esp
80100e5e:	8b 75 08             	mov    0x8(%ebp),%esi
  int r;

  if(f->writable == 0)
80100e61:	80 7e 09 00          	cmpb   $0x0,0x9(%esi)
80100e65:	0f 84 d0 00 00 00    	je     80100f3b <filewrite+0xe6>
    return -1;
  if(f->type == FD_PIPE)
80100e6b:	8b 06                	mov    (%esi),%eax
80100e6d:	83 f8 01             	cmp    $0x1,%eax
80100e70:	74 12                	je     80100e84 <filewrite+0x2f>
    return pipewrite(f->pipe, addr, n);
  if(f->type == FD_INODE){
80100e72:	83 f8 02             	cmp    $0x2,%eax
80100e75:	0f 85 b3 00 00 00    	jne    80100f2e <filewrite+0xd9>
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * 512;
    int i = 0;
80100e7b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100e82:	eb 66                	jmp    80100eea <filewrite+0x95>
    return pipewrite(f->pipe, addr, n);
80100e84:	83 ec 04             	sub    $0x4,%esp
80100e87:	ff 75 10             	push   0x10(%ebp)
80100e8a:	ff 75 0c             	push   0xc(%ebp)
80100e8d:	ff 76 0c             	push   0xc(%esi)
80100e90:	e8 e8 1f 00 00       	call   80102e7d <pipewrite>
80100e95:	83 c4 10             	add    $0x10,%esp
80100e98:	e9 84 00 00 00       	jmp    80100f21 <filewrite+0xcc>
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
80100e9d:	e8 dc 18 00 00       	call   8010277e <begin_op>
      ilock(f->ip);
80100ea2:	83 ec 0c             	sub    $0xc,%esp
80100ea5:	ff 76 10             	push   0x10(%esi)
80100ea8:	e8 c2 06 00 00       	call   8010156f <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80100ead:	57                   	push   %edi
80100eae:	ff 76 14             	push   0x14(%esi)
80100eb1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eb4:	03 45 0c             	add    0xc(%ebp),%eax
80100eb7:	50                   	push   %eax
80100eb8:	ff 76 10             	push   0x10(%esi)
80100ebb:	e8 9e 09 00 00       	call   8010185e <writei>
80100ec0:	89 c3                	mov    %eax,%ebx
80100ec2:	83 c4 20             	add    $0x20,%esp
80100ec5:	85 c0                	test   %eax,%eax
80100ec7:	7e 03                	jle    80100ecc <filewrite+0x77>
        f->off += r;
80100ec9:	01 46 14             	add    %eax,0x14(%esi)
      iunlock(f->ip);
80100ecc:	83 ec 0c             	sub    $0xc,%esp
80100ecf:	ff 76 10             	push   0x10(%esi)
80100ed2:	e8 5a 07 00 00       	call   80101631 <iunlock>
      end_op();
80100ed7:	e8 1c 19 00 00       	call   801027f8 <end_op>

      if(r < 0)
80100edc:	83 c4 10             	add    $0x10,%esp
80100edf:	85 db                	test   %ebx,%ebx
80100ee1:	78 31                	js     80100f14 <filewrite+0xbf>
        break;
      if(r != n1)
80100ee3:	39 df                	cmp    %ebx,%edi
80100ee5:	75 20                	jne    80100f07 <filewrite+0xb2>
        panic("short filewrite");
      i += r;
80100ee7:	01 5d e4             	add    %ebx,-0x1c(%ebp)
    while(i < n){
80100eea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eed:	3b 45 10             	cmp    0x10(%ebp),%eax
80100ef0:	7d 22                	jge    80100f14 <filewrite+0xbf>
      int n1 = n - i;
80100ef2:	8b 7d 10             	mov    0x10(%ebp),%edi
80100ef5:	2b 7d e4             	sub    -0x1c(%ebp),%edi
      if(n1 > max)
80100ef8:	81 ff 00 06 00 00    	cmp    $0x600,%edi
80100efe:	7e 9d                	jle    80100e9d <filewrite+0x48>
        n1 = max;
80100f00:	bf 00 06 00 00       	mov    $0x600,%edi
80100f05:	eb 96                	jmp    80100e9d <filewrite+0x48>
        panic("short filewrite");
80100f07:	83 ec 0c             	sub    $0xc,%esp
80100f0a:	68 0f 69 10 80       	push   $0x8010690f
80100f0f:	e8 34 f4 ff ff       	call   80100348 <panic>
    }
    return i == n ? n : -1;
80100f14:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100f17:	3b 45 10             	cmp    0x10(%ebp),%eax
80100f1a:	74 0d                	je     80100f29 <filewrite+0xd4>
80100f1c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  panic("filewrite");
}
80100f21:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100f24:	5b                   	pop    %ebx
80100f25:	5e                   	pop    %esi
80100f26:	5f                   	pop    %edi
80100f27:	5d                   	pop    %ebp
80100f28:	c3                   	ret    
    return i == n ? n : -1;
80100f29:	8b 45 10             	mov    0x10(%ebp),%eax
80100f2c:	eb f3                	jmp    80100f21 <filewrite+0xcc>
  panic("filewrite");
80100f2e:	83 ec 0c             	sub    $0xc,%esp
80100f31:	68 15 69 10 80       	push   $0x80106915
80100f36:	e8 0d f4 ff ff       	call   80100348 <panic>
    return -1;
80100f3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f40:	eb df                	jmp    80100f21 <filewrite+0xcc>

80100f42 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80100f42:	55                   	push   %ebp
80100f43:	89 e5                	mov    %esp,%ebp
80100f45:	57                   	push   %edi
80100f46:	56                   	push   %esi
80100f47:	53                   	push   %ebx
80100f48:	83 ec 0c             	sub    $0xc,%esp
80100f4b:	89 d6                	mov    %edx,%esi
  char *s;
  int len;

  while(*path == '/')
80100f4d:	eb 03                	jmp    80100f52 <skipelem+0x10>
    path++;
80100f4f:	83 c0 01             	add    $0x1,%eax
  while(*path == '/')
80100f52:	0f b6 10             	movzbl (%eax),%edx
80100f55:	80 fa 2f             	cmp    $0x2f,%dl
80100f58:	74 f5                	je     80100f4f <skipelem+0xd>
  if(*path == 0)
80100f5a:	84 d2                	test   %dl,%dl
80100f5c:	74 53                	je     80100fb1 <skipelem+0x6f>
80100f5e:	89 c3                	mov    %eax,%ebx
80100f60:	eb 03                	jmp    80100f65 <skipelem+0x23>
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
    path++;
80100f62:	83 c3 01             	add    $0x1,%ebx
  while(*path != '/' && *path != 0)
80100f65:	0f b6 13             	movzbl (%ebx),%edx
80100f68:	80 fa 2f             	cmp    $0x2f,%dl
80100f6b:	74 04                	je     80100f71 <skipelem+0x2f>
80100f6d:	84 d2                	test   %dl,%dl
80100f6f:	75 f1                	jne    80100f62 <skipelem+0x20>
  len = path - s;
80100f71:	89 df                	mov    %ebx,%edi
80100f73:	29 c7                	sub    %eax,%edi
  if(len >= DIRSIZ)
80100f75:	83 ff 0d             	cmp    $0xd,%edi
80100f78:	7e 11                	jle    80100f8b <skipelem+0x49>
    memmove(name, s, DIRSIZ);
80100f7a:	83 ec 04             	sub    $0x4,%esp
80100f7d:	6a 0e                	push   $0xe
80100f7f:	50                   	push   %eax
80100f80:	56                   	push   %esi
80100f81:	e8 1e 2e 00 00       	call   80103da4 <memmove>
80100f86:	83 c4 10             	add    $0x10,%esp
80100f89:	eb 17                	jmp    80100fa2 <skipelem+0x60>
  else {
    memmove(name, s, len);
80100f8b:	83 ec 04             	sub    $0x4,%esp
80100f8e:	57                   	push   %edi
80100f8f:	50                   	push   %eax
80100f90:	56                   	push   %esi
80100f91:	e8 0e 2e 00 00       	call   80103da4 <memmove>
    name[len] = 0;
80100f96:	c6 04 3e 00          	movb   $0x0,(%esi,%edi,1)
80100f9a:	83 c4 10             	add    $0x10,%esp
80100f9d:	eb 03                	jmp    80100fa2 <skipelem+0x60>
  }
  while(*path == '/')
    path++;
80100f9f:	83 c3 01             	add    $0x1,%ebx
  while(*path == '/')
80100fa2:	80 3b 2f             	cmpb   $0x2f,(%ebx)
80100fa5:	74 f8                	je     80100f9f <skipelem+0x5d>
  return path;
}
80100fa7:	89 d8                	mov    %ebx,%eax
80100fa9:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100fac:	5b                   	pop    %ebx
80100fad:	5e                   	pop    %esi
80100fae:	5f                   	pop    %edi
80100faf:	5d                   	pop    %ebp
80100fb0:	c3                   	ret    
    return 0;
80100fb1:	bb 00 00 00 00       	mov    $0x0,%ebx
80100fb6:	eb ef                	jmp    80100fa7 <skipelem+0x65>

80100fb8 <bzero>:
{
80100fb8:	55                   	push   %ebp
80100fb9:	89 e5                	mov    %esp,%ebp
80100fbb:	53                   	push   %ebx
80100fbc:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, bno);
80100fbf:	52                   	push   %edx
80100fc0:	50                   	push   %eax
80100fc1:	e8 a6 f1 ff ff       	call   8010016c <bread>
80100fc6:	89 c3                	mov    %eax,%ebx
  memset(bp->data, 0, BSIZE);
80100fc8:	8d 40 5c             	lea    0x5c(%eax),%eax
80100fcb:	83 c4 0c             	add    $0xc,%esp
80100fce:	68 00 02 00 00       	push   $0x200
80100fd3:	6a 00                	push   $0x0
80100fd5:	50                   	push   %eax
80100fd6:	e8 51 2d 00 00       	call   80103d2c <memset>
  log_write(bp);
80100fdb:	89 1c 24             	mov    %ebx,(%esp)
80100fde:	e8 c4 18 00 00       	call   801028a7 <log_write>
  brelse(bp);
80100fe3:	89 1c 24             	mov    %ebx,(%esp)
80100fe6:	e8 ea f1 ff ff       	call   801001d5 <brelse>
}
80100feb:	83 c4 10             	add    $0x10,%esp
80100fee:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100ff1:	c9                   	leave  
80100ff2:	c3                   	ret    

80100ff3 <bfree>:
{
80100ff3:	55                   	push   %ebp
80100ff4:	89 e5                	mov    %esp,%ebp
80100ff6:	56                   	push   %esi
80100ff7:	53                   	push   %ebx
80100ff8:	89 c3                	mov    %eax,%ebx
80100ffa:	89 d6                	mov    %edx,%esi
  bp = bread(dev, BBLOCK(b, sb));
80100ffc:	89 d0                	mov    %edx,%eax
80100ffe:	c1 e8 0c             	shr    $0xc,%eax
80101001:	83 ec 08             	sub    $0x8,%esp
80101004:	03 05 cc 15 11 80    	add    0x801115cc,%eax
8010100a:	50                   	push   %eax
8010100b:	53                   	push   %ebx
8010100c:	e8 5b f1 ff ff       	call   8010016c <bread>
80101011:	89 c3                	mov    %eax,%ebx
  bi = b % BPB;
80101013:	89 f2                	mov    %esi,%edx
80101015:	81 e2 ff 0f 00 00    	and    $0xfff,%edx
  m = 1 << (bi % 8);
8010101b:	89 f1                	mov    %esi,%ecx
8010101d:	83 e1 07             	and    $0x7,%ecx
80101020:	b8 01 00 00 00       	mov    $0x1,%eax
80101025:	d3 e0                	shl    %cl,%eax
  if((bp->data[bi/8] & m) == 0)
80101027:	83 c4 10             	add    $0x10,%esp
8010102a:	c1 fa 03             	sar    $0x3,%edx
8010102d:	0f b6 4c 13 5c       	movzbl 0x5c(%ebx,%edx,1),%ecx
80101032:	0f b6 f1             	movzbl %cl,%esi
80101035:	85 c6                	test   %eax,%esi
80101037:	74 23                	je     8010105c <bfree+0x69>
  bp->data[bi/8] &= ~m;
80101039:	f7 d0                	not    %eax
8010103b:	21 c8                	and    %ecx,%eax
8010103d:	88 44 13 5c          	mov    %al,0x5c(%ebx,%edx,1)
  log_write(bp);
80101041:	83 ec 0c             	sub    $0xc,%esp
80101044:	53                   	push   %ebx
80101045:	e8 5d 18 00 00       	call   801028a7 <log_write>
  brelse(bp);
8010104a:	89 1c 24             	mov    %ebx,(%esp)
8010104d:	e8 83 f1 ff ff       	call   801001d5 <brelse>
}
80101052:	83 c4 10             	add    $0x10,%esp
80101055:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101058:	5b                   	pop    %ebx
80101059:	5e                   	pop    %esi
8010105a:	5d                   	pop    %ebp
8010105b:	c3                   	ret    
    panic("freeing free block");
8010105c:	83 ec 0c             	sub    $0xc,%esp
8010105f:	68 1f 69 10 80       	push   $0x8010691f
80101064:	e8 df f2 ff ff       	call   80100348 <panic>

80101069 <balloc>:
{
80101069:	55                   	push   %ebp
8010106a:	89 e5                	mov    %esp,%ebp
8010106c:	57                   	push   %edi
8010106d:	56                   	push   %esi
8010106e:	53                   	push   %ebx
8010106f:	83 ec 1c             	sub    $0x1c,%esp
80101072:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101075:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010107c:	eb 15                	jmp    80101093 <balloc+0x2a>
    brelse(bp);
8010107e:	83 ec 0c             	sub    $0xc,%esp
80101081:	ff 75 e0             	push   -0x20(%ebp)
80101084:	e8 4c f1 ff ff       	call   801001d5 <brelse>
  for(b = 0; b < sb.size; b += BPB){
80101089:	81 45 e4 00 10 00 00 	addl   $0x1000,-0x1c(%ebp)
80101090:	83 c4 10             	add    $0x10,%esp
80101093:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101096:	39 05 b4 15 11 80    	cmp    %eax,0x801115b4
8010109c:	76 75                	jbe    80101113 <balloc+0xaa>
    bp = bread(dev, BBLOCK(b, sb));
8010109e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801010a1:	8d 83 ff 0f 00 00    	lea    0xfff(%ebx),%eax
801010a7:	85 db                	test   %ebx,%ebx
801010a9:	0f 49 c3             	cmovns %ebx,%eax
801010ac:	c1 f8 0c             	sar    $0xc,%eax
801010af:	83 ec 08             	sub    $0x8,%esp
801010b2:	03 05 cc 15 11 80    	add    0x801115cc,%eax
801010b8:	50                   	push   %eax
801010b9:	ff 75 d8             	push   -0x28(%ebp)
801010bc:	e8 ab f0 ff ff       	call   8010016c <bread>
801010c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801010c4:	83 c4 10             	add    $0x10,%esp
801010c7:	b8 00 00 00 00       	mov    $0x0,%eax
801010cc:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801010d1:	7f ab                	jg     8010107e <balloc+0x15>
801010d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
801010d6:	8d 1c 07             	lea    (%edi,%eax,1),%ebx
801010d9:	3b 1d b4 15 11 80    	cmp    0x801115b4,%ebx
801010df:	73 9d                	jae    8010107e <balloc+0x15>
      m = 1 << (bi % 8);
801010e1:	89 c1                	mov    %eax,%ecx
801010e3:	83 e1 07             	and    $0x7,%ecx
801010e6:	ba 01 00 00 00       	mov    $0x1,%edx
801010eb:	d3 e2                	shl    %cl,%edx
801010ed:	89 d1                	mov    %edx,%ecx
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801010ef:	8d 50 07             	lea    0x7(%eax),%edx
801010f2:	85 c0                	test   %eax,%eax
801010f4:	0f 49 d0             	cmovns %eax,%edx
801010f7:	c1 fa 03             	sar    $0x3,%edx
801010fa:	89 55 dc             	mov    %edx,-0x24(%ebp)
801010fd:	8b 75 e0             	mov    -0x20(%ebp),%esi
80101100:	0f b6 74 16 5c       	movzbl 0x5c(%esi,%edx,1),%esi
80101105:	89 f2                	mov    %esi,%edx
80101107:	0f b6 fa             	movzbl %dl,%edi
8010110a:	85 cf                	test   %ecx,%edi
8010110c:	74 12                	je     80101120 <balloc+0xb7>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010110e:	83 c0 01             	add    $0x1,%eax
80101111:	eb b9                	jmp    801010cc <balloc+0x63>
  panic("balloc: out of blocks");
80101113:	83 ec 0c             	sub    $0xc,%esp
80101116:	68 32 69 10 80       	push   $0x80106932
8010111b:	e8 28 f2 ff ff       	call   80100348 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
80101120:	8b 55 dc             	mov    -0x24(%ebp),%edx
80101123:	09 f1                	or     %esi,%ecx
80101125:	8b 7d e0             	mov    -0x20(%ebp),%edi
80101128:	88 4c 17 5c          	mov    %cl,0x5c(%edi,%edx,1)
        log_write(bp);
8010112c:	83 ec 0c             	sub    $0xc,%esp
8010112f:	57                   	push   %edi
80101130:	e8 72 17 00 00       	call   801028a7 <log_write>
        brelse(bp);
80101135:	89 3c 24             	mov    %edi,(%esp)
80101138:	e8 98 f0 ff ff       	call   801001d5 <brelse>
        bzero(dev, b + bi);
8010113d:	89 da                	mov    %ebx,%edx
8010113f:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101142:	e8 71 fe ff ff       	call   80100fb8 <bzero>
}
80101147:	89 d8                	mov    %ebx,%eax
80101149:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010114c:	5b                   	pop    %ebx
8010114d:	5e                   	pop    %esi
8010114e:	5f                   	pop    %edi
8010114f:	5d                   	pop    %ebp
80101150:	c3                   	ret    

80101151 <bmap>:
{
80101151:	55                   	push   %ebp
80101152:	89 e5                	mov    %esp,%ebp
80101154:	57                   	push   %edi
80101155:	56                   	push   %esi
80101156:	53                   	push   %ebx
80101157:	83 ec 1c             	sub    $0x1c,%esp
8010115a:	89 c3                	mov    %eax,%ebx
8010115c:	89 d7                	mov    %edx,%edi
  if(bn < NDIRECT){
8010115e:	83 fa 0b             	cmp    $0xb,%edx
80101161:	76 45                	jbe    801011a8 <bmap+0x57>
  bn -= NDIRECT;
80101163:	8d 72 f4             	lea    -0xc(%edx),%esi
  if(bn < NINDIRECT){
80101166:	83 fe 7f             	cmp    $0x7f,%esi
80101169:	77 7f                	ja     801011ea <bmap+0x99>
    if((addr = ip->addrs[NDIRECT]) == 0)
8010116b:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101171:	85 c0                	test   %eax,%eax
80101173:	74 4a                	je     801011bf <bmap+0x6e>
    bp = bread(ip->dev, addr);
80101175:	83 ec 08             	sub    $0x8,%esp
80101178:	50                   	push   %eax
80101179:	ff 33                	push   (%ebx)
8010117b:	e8 ec ef ff ff       	call   8010016c <bread>
80101180:	89 c7                	mov    %eax,%edi
    if((addr = a[bn]) == 0){
80101182:	8d 44 b0 5c          	lea    0x5c(%eax,%esi,4),%eax
80101186:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80101189:	8b 30                	mov    (%eax),%esi
8010118b:	83 c4 10             	add    $0x10,%esp
8010118e:	85 f6                	test   %esi,%esi
80101190:	74 3c                	je     801011ce <bmap+0x7d>
    brelse(bp);
80101192:	83 ec 0c             	sub    $0xc,%esp
80101195:	57                   	push   %edi
80101196:	e8 3a f0 ff ff       	call   801001d5 <brelse>
    return addr;
8010119b:	83 c4 10             	add    $0x10,%esp
}
8010119e:	89 f0                	mov    %esi,%eax
801011a0:	8d 65 f4             	lea    -0xc(%ebp),%esp
801011a3:	5b                   	pop    %ebx
801011a4:	5e                   	pop    %esi
801011a5:	5f                   	pop    %edi
801011a6:	5d                   	pop    %ebp
801011a7:	c3                   	ret    
    if((addr = ip->addrs[bn]) == 0)
801011a8:	8b 74 90 5c          	mov    0x5c(%eax,%edx,4),%esi
801011ac:	85 f6                	test   %esi,%esi
801011ae:	75 ee                	jne    8010119e <bmap+0x4d>
      ip->addrs[bn] = addr = balloc(ip->dev);
801011b0:	8b 00                	mov    (%eax),%eax
801011b2:	e8 b2 fe ff ff       	call   80101069 <balloc>
801011b7:	89 c6                	mov    %eax,%esi
801011b9:	89 44 bb 5c          	mov    %eax,0x5c(%ebx,%edi,4)
    return addr;
801011bd:	eb df                	jmp    8010119e <bmap+0x4d>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801011bf:	8b 03                	mov    (%ebx),%eax
801011c1:	e8 a3 fe ff ff       	call   80101069 <balloc>
801011c6:	89 83 8c 00 00 00    	mov    %eax,0x8c(%ebx)
801011cc:	eb a7                	jmp    80101175 <bmap+0x24>
      a[bn] = addr = balloc(ip->dev);
801011ce:	8b 03                	mov    (%ebx),%eax
801011d0:	e8 94 fe ff ff       	call   80101069 <balloc>
801011d5:	89 c6                	mov    %eax,%esi
801011d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801011da:	89 30                	mov    %esi,(%eax)
      log_write(bp);
801011dc:	83 ec 0c             	sub    $0xc,%esp
801011df:	57                   	push   %edi
801011e0:	e8 c2 16 00 00       	call   801028a7 <log_write>
801011e5:	83 c4 10             	add    $0x10,%esp
801011e8:	eb a8                	jmp    80101192 <bmap+0x41>
  panic("bmap: out of range");
801011ea:	83 ec 0c             	sub    $0xc,%esp
801011ed:	68 48 69 10 80       	push   $0x80106948
801011f2:	e8 51 f1 ff ff       	call   80100348 <panic>

801011f7 <iget>:
{
801011f7:	55                   	push   %ebp
801011f8:	89 e5                	mov    %esp,%ebp
801011fa:	57                   	push   %edi
801011fb:	56                   	push   %esi
801011fc:	53                   	push   %ebx
801011fd:	83 ec 28             	sub    $0x28,%esp
80101200:	89 c7                	mov    %eax,%edi
80101202:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  acquire(&icache.lock);
80101205:	68 60 f9 10 80       	push   $0x8010f960
8010120a:	e8 71 2a 00 00       	call   80103c80 <acquire>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010120f:	83 c4 10             	add    $0x10,%esp
  empty = 0;
80101212:	be 00 00 00 00       	mov    $0x0,%esi
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101217:	bb 94 f9 10 80       	mov    $0x8010f994,%ebx
8010121c:	eb 0a                	jmp    80101228 <iget+0x31>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010121e:	85 f6                	test   %esi,%esi
80101220:	74 3b                	je     8010125d <iget+0x66>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101222:	81 c3 90 00 00 00    	add    $0x90,%ebx
80101228:	81 fb b4 15 11 80    	cmp    $0x801115b4,%ebx
8010122e:	73 35                	jae    80101265 <iget+0x6e>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101230:	8b 43 08             	mov    0x8(%ebx),%eax
80101233:	85 c0                	test   %eax,%eax
80101235:	7e e7                	jle    8010121e <iget+0x27>
80101237:	39 3b                	cmp    %edi,(%ebx)
80101239:	75 e3                	jne    8010121e <iget+0x27>
8010123b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
8010123e:	39 4b 04             	cmp    %ecx,0x4(%ebx)
80101241:	75 db                	jne    8010121e <iget+0x27>
      ip->ref++;
80101243:	83 c0 01             	add    $0x1,%eax
80101246:	89 43 08             	mov    %eax,0x8(%ebx)
      release(&icache.lock);
80101249:	83 ec 0c             	sub    $0xc,%esp
8010124c:	68 60 f9 10 80       	push   $0x8010f960
80101251:	e8 8f 2a 00 00       	call   80103ce5 <release>
      return ip;
80101256:	83 c4 10             	add    $0x10,%esp
80101259:	89 de                	mov    %ebx,%esi
8010125b:	eb 32                	jmp    8010128f <iget+0x98>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010125d:	85 c0                	test   %eax,%eax
8010125f:	75 c1                	jne    80101222 <iget+0x2b>
      empty = ip;
80101261:	89 de                	mov    %ebx,%esi
80101263:	eb bd                	jmp    80101222 <iget+0x2b>
  if(empty == 0)
80101265:	85 f6                	test   %esi,%esi
80101267:	74 30                	je     80101299 <iget+0xa2>
  ip->dev = dev;
80101269:	89 3e                	mov    %edi,(%esi)
  ip->inum = inum;
8010126b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010126e:	89 46 04             	mov    %eax,0x4(%esi)
  ip->ref = 1;
80101271:	c7 46 08 01 00 00 00 	movl   $0x1,0x8(%esi)
  ip->valid = 0;
80101278:	c7 46 4c 00 00 00 00 	movl   $0x0,0x4c(%esi)
  release(&icache.lock);
8010127f:	83 ec 0c             	sub    $0xc,%esp
80101282:	68 60 f9 10 80       	push   $0x8010f960
80101287:	e8 59 2a 00 00       	call   80103ce5 <release>
  return ip;
8010128c:	83 c4 10             	add    $0x10,%esp
}
8010128f:	89 f0                	mov    %esi,%eax
80101291:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101294:	5b                   	pop    %ebx
80101295:	5e                   	pop    %esi
80101296:	5f                   	pop    %edi
80101297:	5d                   	pop    %ebp
80101298:	c3                   	ret    
    panic("iget: no inodes");
80101299:	83 ec 0c             	sub    $0xc,%esp
8010129c:	68 5b 69 10 80       	push   $0x8010695b
801012a1:	e8 a2 f0 ff ff       	call   80100348 <panic>

801012a6 <readsb>:
{
801012a6:	55                   	push   %ebp
801012a7:	89 e5                	mov    %esp,%ebp
801012a9:	53                   	push   %ebx
801012aa:	83 ec 0c             	sub    $0xc,%esp
  bp = bread(dev, 1);
801012ad:	6a 01                	push   $0x1
801012af:	ff 75 08             	push   0x8(%ebp)
801012b2:	e8 b5 ee ff ff       	call   8010016c <bread>
801012b7:	89 c3                	mov    %eax,%ebx
  memmove(sb, bp->data, sizeof(*sb));
801012b9:	8d 40 5c             	lea    0x5c(%eax),%eax
801012bc:	83 c4 0c             	add    $0xc,%esp
801012bf:	6a 1c                	push   $0x1c
801012c1:	50                   	push   %eax
801012c2:	ff 75 0c             	push   0xc(%ebp)
801012c5:	e8 da 2a 00 00       	call   80103da4 <memmove>
  brelse(bp);
801012ca:	89 1c 24             	mov    %ebx,(%esp)
801012cd:	e8 03 ef ff ff       	call   801001d5 <brelse>
}
801012d2:	83 c4 10             	add    $0x10,%esp
801012d5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801012d8:	c9                   	leave  
801012d9:	c3                   	ret    

801012da <iinit>:
{
801012da:	55                   	push   %ebp
801012db:	89 e5                	mov    %esp,%ebp
801012dd:	53                   	push   %ebx
801012de:	83 ec 0c             	sub    $0xc,%esp
  initlock(&icache.lock, "icache");
801012e1:	68 6b 69 10 80       	push   $0x8010696b
801012e6:	68 60 f9 10 80       	push   $0x8010f960
801012eb:	e8 54 28 00 00       	call   80103b44 <initlock>
  for(i = 0; i < NINODE; i++) {
801012f0:	83 c4 10             	add    $0x10,%esp
801012f3:	bb 00 00 00 00       	mov    $0x0,%ebx
801012f8:	eb 21                	jmp    8010131b <iinit+0x41>
    initsleeplock(&icache.inode[i].lock, "inode");
801012fa:	83 ec 08             	sub    $0x8,%esp
801012fd:	68 72 69 10 80       	push   $0x80106972
80101302:	8d 14 db             	lea    (%ebx,%ebx,8),%edx
80101305:	89 d0                	mov    %edx,%eax
80101307:	c1 e0 04             	shl    $0x4,%eax
8010130a:	05 a0 f9 10 80       	add    $0x8010f9a0,%eax
8010130f:	50                   	push   %eax
80101310:	e8 24 27 00 00       	call   80103a39 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
80101315:	83 c3 01             	add    $0x1,%ebx
80101318:	83 c4 10             	add    $0x10,%esp
8010131b:	83 fb 31             	cmp    $0x31,%ebx
8010131e:	7e da                	jle    801012fa <iinit+0x20>
  readsb(dev, &sb);
80101320:	83 ec 08             	sub    $0x8,%esp
80101323:	68 b4 15 11 80       	push   $0x801115b4
80101328:	ff 75 08             	push   0x8(%ebp)
8010132b:	e8 76 ff ff ff       	call   801012a6 <readsb>
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101330:	ff 35 cc 15 11 80    	push   0x801115cc
80101336:	ff 35 c8 15 11 80    	push   0x801115c8
8010133c:	ff 35 c4 15 11 80    	push   0x801115c4
80101342:	ff 35 c0 15 11 80    	push   0x801115c0
80101348:	ff 35 bc 15 11 80    	push   0x801115bc
8010134e:	ff 35 b8 15 11 80    	push   0x801115b8
80101354:	ff 35 b4 15 11 80    	push   0x801115b4
8010135a:	68 d8 69 10 80       	push   $0x801069d8
8010135f:	e8 a3 f2 ff ff       	call   80100607 <cprintf>
}
80101364:	83 c4 30             	add    $0x30,%esp
80101367:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010136a:	c9                   	leave  
8010136b:	c3                   	ret    

8010136c <ialloc>:
{
8010136c:	55                   	push   %ebp
8010136d:	89 e5                	mov    %esp,%ebp
8010136f:	57                   	push   %edi
80101370:	56                   	push   %esi
80101371:	53                   	push   %ebx
80101372:	83 ec 1c             	sub    $0x1c,%esp
80101375:	8b 45 0c             	mov    0xc(%ebp),%eax
80101378:	89 45 e0             	mov    %eax,-0x20(%ebp)
  for(inum = 1; inum < sb.ninodes; inum++){
8010137b:	bb 01 00 00 00       	mov    $0x1,%ebx
80101380:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
80101383:	39 1d bc 15 11 80    	cmp    %ebx,0x801115bc
80101389:	76 3f                	jbe    801013ca <ialloc+0x5e>
    bp = bread(dev, IBLOCK(inum, sb));
8010138b:	89 d8                	mov    %ebx,%eax
8010138d:	c1 e8 03             	shr    $0x3,%eax
80101390:	83 ec 08             	sub    $0x8,%esp
80101393:	03 05 c8 15 11 80    	add    0x801115c8,%eax
80101399:	50                   	push   %eax
8010139a:	ff 75 08             	push   0x8(%ebp)
8010139d:	e8 ca ed ff ff       	call   8010016c <bread>
801013a2:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + inum%IPB;
801013a4:	89 d8                	mov    %ebx,%eax
801013a6:	83 e0 07             	and    $0x7,%eax
801013a9:	c1 e0 06             	shl    $0x6,%eax
801013ac:	8d 7c 06 5c          	lea    0x5c(%esi,%eax,1),%edi
    if(dip->type == 0){  // a free inode
801013b0:	83 c4 10             	add    $0x10,%esp
801013b3:	66 83 3f 00          	cmpw   $0x0,(%edi)
801013b7:	74 1e                	je     801013d7 <ialloc+0x6b>
    brelse(bp);
801013b9:	83 ec 0c             	sub    $0xc,%esp
801013bc:	56                   	push   %esi
801013bd:	e8 13 ee ff ff       	call   801001d5 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
801013c2:	83 c3 01             	add    $0x1,%ebx
801013c5:	83 c4 10             	add    $0x10,%esp
801013c8:	eb b6                	jmp    80101380 <ialloc+0x14>
  panic("ialloc: no inodes");
801013ca:	83 ec 0c             	sub    $0xc,%esp
801013cd:	68 78 69 10 80       	push   $0x80106978
801013d2:	e8 71 ef ff ff       	call   80100348 <panic>
      memset(dip, 0, sizeof(*dip));
801013d7:	83 ec 04             	sub    $0x4,%esp
801013da:	6a 40                	push   $0x40
801013dc:	6a 00                	push   $0x0
801013de:	57                   	push   %edi
801013df:	e8 48 29 00 00       	call   80103d2c <memset>
      dip->type = type;
801013e4:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801013e8:	66 89 07             	mov    %ax,(%edi)
      log_write(bp);   // mark it allocated on the disk
801013eb:	89 34 24             	mov    %esi,(%esp)
801013ee:	e8 b4 14 00 00       	call   801028a7 <log_write>
      brelse(bp);
801013f3:	89 34 24             	mov    %esi,(%esp)
801013f6:	e8 da ed ff ff       	call   801001d5 <brelse>
      return iget(dev, inum);
801013fb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801013fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101401:	e8 f1 fd ff ff       	call   801011f7 <iget>
}
80101406:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101409:	5b                   	pop    %ebx
8010140a:	5e                   	pop    %esi
8010140b:	5f                   	pop    %edi
8010140c:	5d                   	pop    %ebp
8010140d:	c3                   	ret    

8010140e <iupdate>:
{
8010140e:	55                   	push   %ebp
8010140f:	89 e5                	mov    %esp,%ebp
80101411:	56                   	push   %esi
80101412:	53                   	push   %ebx
80101413:	8b 5d 08             	mov    0x8(%ebp),%ebx
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101416:	8b 43 04             	mov    0x4(%ebx),%eax
80101419:	c1 e8 03             	shr    $0x3,%eax
8010141c:	83 ec 08             	sub    $0x8,%esp
8010141f:	03 05 c8 15 11 80    	add    0x801115c8,%eax
80101425:	50                   	push   %eax
80101426:	ff 33                	push   (%ebx)
80101428:	e8 3f ed ff ff       	call   8010016c <bread>
8010142d:	89 c6                	mov    %eax,%esi
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010142f:	8b 43 04             	mov    0x4(%ebx),%eax
80101432:	83 e0 07             	and    $0x7,%eax
80101435:	c1 e0 06             	shl    $0x6,%eax
80101438:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
  dip->type = ip->type;
8010143c:	0f b7 53 50          	movzwl 0x50(%ebx),%edx
80101440:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101443:	0f b7 53 52          	movzwl 0x52(%ebx),%edx
80101447:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
8010144b:	0f b7 53 54          	movzwl 0x54(%ebx),%edx
8010144f:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101453:	0f b7 53 56          	movzwl 0x56(%ebx),%edx
80101457:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
8010145b:	8b 53 58             	mov    0x58(%ebx),%edx
8010145e:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101461:	83 c3 5c             	add    $0x5c,%ebx
80101464:	83 c0 0c             	add    $0xc,%eax
80101467:	83 c4 0c             	add    $0xc,%esp
8010146a:	6a 34                	push   $0x34
8010146c:	53                   	push   %ebx
8010146d:	50                   	push   %eax
8010146e:	e8 31 29 00 00       	call   80103da4 <memmove>
  log_write(bp);
80101473:	89 34 24             	mov    %esi,(%esp)
80101476:	e8 2c 14 00 00       	call   801028a7 <log_write>
  brelse(bp);
8010147b:	89 34 24             	mov    %esi,(%esp)
8010147e:	e8 52 ed ff ff       	call   801001d5 <brelse>
}
80101483:	83 c4 10             	add    $0x10,%esp
80101486:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101489:	5b                   	pop    %ebx
8010148a:	5e                   	pop    %esi
8010148b:	5d                   	pop    %ebp
8010148c:	c3                   	ret    

8010148d <itrunc>:
{
8010148d:	55                   	push   %ebp
8010148e:	89 e5                	mov    %esp,%ebp
80101490:	57                   	push   %edi
80101491:	56                   	push   %esi
80101492:	53                   	push   %ebx
80101493:	83 ec 1c             	sub    $0x1c,%esp
80101496:	89 c6                	mov    %eax,%esi
  for(i = 0; i < NDIRECT; i++){
80101498:	bb 00 00 00 00       	mov    $0x0,%ebx
8010149d:	eb 03                	jmp    801014a2 <itrunc+0x15>
8010149f:	83 c3 01             	add    $0x1,%ebx
801014a2:	83 fb 0b             	cmp    $0xb,%ebx
801014a5:	7f 19                	jg     801014c0 <itrunc+0x33>
    if(ip->addrs[i]){
801014a7:	8b 54 9e 5c          	mov    0x5c(%esi,%ebx,4),%edx
801014ab:	85 d2                	test   %edx,%edx
801014ad:	74 f0                	je     8010149f <itrunc+0x12>
      bfree(ip->dev, ip->addrs[i]);
801014af:	8b 06                	mov    (%esi),%eax
801014b1:	e8 3d fb ff ff       	call   80100ff3 <bfree>
      ip->addrs[i] = 0;
801014b6:	c7 44 9e 5c 00 00 00 	movl   $0x0,0x5c(%esi,%ebx,4)
801014bd:	00 
801014be:	eb df                	jmp    8010149f <itrunc+0x12>
  if(ip->addrs[NDIRECT]){
801014c0:	8b 86 8c 00 00 00    	mov    0x8c(%esi),%eax
801014c6:	85 c0                	test   %eax,%eax
801014c8:	75 1b                	jne    801014e5 <itrunc+0x58>
  ip->size = 0;
801014ca:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
  iupdate(ip);
801014d1:	83 ec 0c             	sub    $0xc,%esp
801014d4:	56                   	push   %esi
801014d5:	e8 34 ff ff ff       	call   8010140e <iupdate>
}
801014da:	83 c4 10             	add    $0x10,%esp
801014dd:	8d 65 f4             	lea    -0xc(%ebp),%esp
801014e0:	5b                   	pop    %ebx
801014e1:	5e                   	pop    %esi
801014e2:	5f                   	pop    %edi
801014e3:	5d                   	pop    %ebp
801014e4:	c3                   	ret    
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801014e5:	83 ec 08             	sub    $0x8,%esp
801014e8:	50                   	push   %eax
801014e9:	ff 36                	push   (%esi)
801014eb:	e8 7c ec ff ff       	call   8010016c <bread>
801014f0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    a = (uint*)bp->data;
801014f3:	8d 78 5c             	lea    0x5c(%eax),%edi
    for(j = 0; j < NINDIRECT; j++){
801014f6:	83 c4 10             	add    $0x10,%esp
801014f9:	bb 00 00 00 00       	mov    $0x0,%ebx
801014fe:	eb 03                	jmp    80101503 <itrunc+0x76>
80101500:	83 c3 01             	add    $0x1,%ebx
80101503:	83 fb 7f             	cmp    $0x7f,%ebx
80101506:	77 10                	ja     80101518 <itrunc+0x8b>
      if(a[j])
80101508:	8b 14 9f             	mov    (%edi,%ebx,4),%edx
8010150b:	85 d2                	test   %edx,%edx
8010150d:	74 f1                	je     80101500 <itrunc+0x73>
        bfree(ip->dev, a[j]);
8010150f:	8b 06                	mov    (%esi),%eax
80101511:	e8 dd fa ff ff       	call   80100ff3 <bfree>
80101516:	eb e8                	jmp    80101500 <itrunc+0x73>
    brelse(bp);
80101518:	83 ec 0c             	sub    $0xc,%esp
8010151b:	ff 75 e4             	push   -0x1c(%ebp)
8010151e:	e8 b2 ec ff ff       	call   801001d5 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101523:	8b 06                	mov    (%esi),%eax
80101525:	8b 96 8c 00 00 00    	mov    0x8c(%esi),%edx
8010152b:	e8 c3 fa ff ff       	call   80100ff3 <bfree>
    ip->addrs[NDIRECT] = 0;
80101530:	c7 86 8c 00 00 00 00 	movl   $0x0,0x8c(%esi)
80101537:	00 00 00 
8010153a:	83 c4 10             	add    $0x10,%esp
8010153d:	eb 8b                	jmp    801014ca <itrunc+0x3d>

8010153f <idup>:
{
8010153f:	55                   	push   %ebp
80101540:	89 e5                	mov    %esp,%ebp
80101542:	53                   	push   %ebx
80101543:	83 ec 10             	sub    $0x10,%esp
80101546:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&icache.lock);
80101549:	68 60 f9 10 80       	push   $0x8010f960
8010154e:	e8 2d 27 00 00       	call   80103c80 <acquire>
  ip->ref++;
80101553:	8b 43 08             	mov    0x8(%ebx),%eax
80101556:	83 c0 01             	add    $0x1,%eax
80101559:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
8010155c:	c7 04 24 60 f9 10 80 	movl   $0x8010f960,(%esp)
80101563:	e8 7d 27 00 00       	call   80103ce5 <release>
}
80101568:	89 d8                	mov    %ebx,%eax
8010156a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010156d:	c9                   	leave  
8010156e:	c3                   	ret    

8010156f <ilock>:
{
8010156f:	55                   	push   %ebp
80101570:	89 e5                	mov    %esp,%ebp
80101572:	56                   	push   %esi
80101573:	53                   	push   %ebx
80101574:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || ip->ref < 1)
80101577:	85 db                	test   %ebx,%ebx
80101579:	74 22                	je     8010159d <ilock+0x2e>
8010157b:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
8010157f:	7e 1c                	jle    8010159d <ilock+0x2e>
  acquiresleep(&ip->lock);
80101581:	83 ec 0c             	sub    $0xc,%esp
80101584:	8d 43 0c             	lea    0xc(%ebx),%eax
80101587:	50                   	push   %eax
80101588:	e8 df 24 00 00       	call   80103a6c <acquiresleep>
  if(ip->valid == 0){
8010158d:	83 c4 10             	add    $0x10,%esp
80101590:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101594:	74 14                	je     801015aa <ilock+0x3b>
}
80101596:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101599:	5b                   	pop    %ebx
8010159a:	5e                   	pop    %esi
8010159b:	5d                   	pop    %ebp
8010159c:	c3                   	ret    
    panic("ilock");
8010159d:	83 ec 0c             	sub    $0xc,%esp
801015a0:	68 8a 69 10 80       	push   $0x8010698a
801015a5:	e8 9e ed ff ff       	call   80100348 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
801015aa:	8b 43 04             	mov    0x4(%ebx),%eax
801015ad:	c1 e8 03             	shr    $0x3,%eax
801015b0:	83 ec 08             	sub    $0x8,%esp
801015b3:	03 05 c8 15 11 80    	add    0x801115c8,%eax
801015b9:	50                   	push   %eax
801015ba:	ff 33                	push   (%ebx)
801015bc:	e8 ab eb ff ff       	call   8010016c <bread>
801015c1:	89 c6                	mov    %eax,%esi
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801015c3:	8b 43 04             	mov    0x4(%ebx),%eax
801015c6:	83 e0 07             	and    $0x7,%eax
801015c9:	c1 e0 06             	shl    $0x6,%eax
801015cc:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
    ip->type = dip->type;
801015d0:	0f b7 10             	movzwl (%eax),%edx
801015d3:	66 89 53 50          	mov    %dx,0x50(%ebx)
    ip->major = dip->major;
801015d7:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801015db:	66 89 53 52          	mov    %dx,0x52(%ebx)
    ip->minor = dip->minor;
801015df:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801015e3:	66 89 53 54          	mov    %dx,0x54(%ebx)
    ip->nlink = dip->nlink;
801015e7:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801015eb:	66 89 53 56          	mov    %dx,0x56(%ebx)
    ip->size = dip->size;
801015ef:	8b 50 08             	mov    0x8(%eax),%edx
801015f2:	89 53 58             	mov    %edx,0x58(%ebx)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801015f5:	83 c0 0c             	add    $0xc,%eax
801015f8:	8d 53 5c             	lea    0x5c(%ebx),%edx
801015fb:	83 c4 0c             	add    $0xc,%esp
801015fe:	6a 34                	push   $0x34
80101600:	50                   	push   %eax
80101601:	52                   	push   %edx
80101602:	e8 9d 27 00 00       	call   80103da4 <memmove>
    brelse(bp);
80101607:	89 34 24             	mov    %esi,(%esp)
8010160a:	e8 c6 eb ff ff       	call   801001d5 <brelse>
    ip->valid = 1;
8010160f:	c7 43 4c 01 00 00 00 	movl   $0x1,0x4c(%ebx)
    if(ip->type == 0)
80101616:	83 c4 10             	add    $0x10,%esp
80101619:	66 83 7b 50 00       	cmpw   $0x0,0x50(%ebx)
8010161e:	0f 85 72 ff ff ff    	jne    80101596 <ilock+0x27>
      panic("ilock: no type");
80101624:	83 ec 0c             	sub    $0xc,%esp
80101627:	68 90 69 10 80       	push   $0x80106990
8010162c:	e8 17 ed ff ff       	call   80100348 <panic>

80101631 <iunlock>:
{
80101631:	55                   	push   %ebp
80101632:	89 e5                	mov    %esp,%ebp
80101634:	56                   	push   %esi
80101635:	53                   	push   %ebx
80101636:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
80101639:	85 db                	test   %ebx,%ebx
8010163b:	74 2c                	je     80101669 <iunlock+0x38>
8010163d:	8d 73 0c             	lea    0xc(%ebx),%esi
80101640:	83 ec 0c             	sub    $0xc,%esp
80101643:	56                   	push   %esi
80101644:	e8 ad 24 00 00       	call   80103af6 <holdingsleep>
80101649:	83 c4 10             	add    $0x10,%esp
8010164c:	85 c0                	test   %eax,%eax
8010164e:	74 19                	je     80101669 <iunlock+0x38>
80101650:	83 7b 08 00          	cmpl   $0x0,0x8(%ebx)
80101654:	7e 13                	jle    80101669 <iunlock+0x38>
  releasesleep(&ip->lock);
80101656:	83 ec 0c             	sub    $0xc,%esp
80101659:	56                   	push   %esi
8010165a:	e8 5c 24 00 00       	call   80103abb <releasesleep>
}
8010165f:	83 c4 10             	add    $0x10,%esp
80101662:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101665:	5b                   	pop    %ebx
80101666:	5e                   	pop    %esi
80101667:	5d                   	pop    %ebp
80101668:	c3                   	ret    
    panic("iunlock");
80101669:	83 ec 0c             	sub    $0xc,%esp
8010166c:	68 9f 69 10 80       	push   $0x8010699f
80101671:	e8 d2 ec ff ff       	call   80100348 <panic>

80101676 <iput>:
{
80101676:	55                   	push   %ebp
80101677:	89 e5                	mov    %esp,%ebp
80101679:	57                   	push   %edi
8010167a:	56                   	push   %esi
8010167b:	53                   	push   %ebx
8010167c:	83 ec 18             	sub    $0x18,%esp
8010167f:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquiresleep(&ip->lock);
80101682:	8d 73 0c             	lea    0xc(%ebx),%esi
80101685:	56                   	push   %esi
80101686:	e8 e1 23 00 00       	call   80103a6c <acquiresleep>
  if(ip->valid && ip->nlink == 0){
8010168b:	83 c4 10             	add    $0x10,%esp
8010168e:	83 7b 4c 00          	cmpl   $0x0,0x4c(%ebx)
80101692:	74 07                	je     8010169b <iput+0x25>
80101694:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
80101699:	74 35                	je     801016d0 <iput+0x5a>
  releasesleep(&ip->lock);
8010169b:	83 ec 0c             	sub    $0xc,%esp
8010169e:	56                   	push   %esi
8010169f:	e8 17 24 00 00       	call   80103abb <releasesleep>
  acquire(&icache.lock);
801016a4:	c7 04 24 60 f9 10 80 	movl   $0x8010f960,(%esp)
801016ab:	e8 d0 25 00 00       	call   80103c80 <acquire>
  ip->ref--;
801016b0:	8b 43 08             	mov    0x8(%ebx),%eax
801016b3:	83 e8 01             	sub    $0x1,%eax
801016b6:	89 43 08             	mov    %eax,0x8(%ebx)
  release(&icache.lock);
801016b9:	c7 04 24 60 f9 10 80 	movl   $0x8010f960,(%esp)
801016c0:	e8 20 26 00 00       	call   80103ce5 <release>
}
801016c5:	83 c4 10             	add    $0x10,%esp
801016c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
801016cb:	5b                   	pop    %ebx
801016cc:	5e                   	pop    %esi
801016cd:	5f                   	pop    %edi
801016ce:	5d                   	pop    %ebp
801016cf:	c3                   	ret    
    acquire(&icache.lock);
801016d0:	83 ec 0c             	sub    $0xc,%esp
801016d3:	68 60 f9 10 80       	push   $0x8010f960
801016d8:	e8 a3 25 00 00       	call   80103c80 <acquire>
    int r = ip->ref;
801016dd:	8b 7b 08             	mov    0x8(%ebx),%edi
    release(&icache.lock);
801016e0:	c7 04 24 60 f9 10 80 	movl   $0x8010f960,(%esp)
801016e7:	e8 f9 25 00 00       	call   80103ce5 <release>
    if(r == 1){
801016ec:	83 c4 10             	add    $0x10,%esp
801016ef:	83 ff 01             	cmp    $0x1,%edi
801016f2:	75 a7                	jne    8010169b <iput+0x25>
      itrunc(ip);
801016f4:	89 d8                	mov    %ebx,%eax
801016f6:	e8 92 fd ff ff       	call   8010148d <itrunc>
      ip->type = 0;
801016fb:	66 c7 43 50 00 00    	movw   $0x0,0x50(%ebx)
      iupdate(ip);
80101701:	83 ec 0c             	sub    $0xc,%esp
80101704:	53                   	push   %ebx
80101705:	e8 04 fd ff ff       	call   8010140e <iupdate>
      ip->valid = 0;
8010170a:	c7 43 4c 00 00 00 00 	movl   $0x0,0x4c(%ebx)
80101711:	83 c4 10             	add    $0x10,%esp
80101714:	eb 85                	jmp    8010169b <iput+0x25>

80101716 <iunlockput>:
{
80101716:	55                   	push   %ebp
80101717:	89 e5                	mov    %esp,%ebp
80101719:	53                   	push   %ebx
8010171a:	83 ec 10             	sub    $0x10,%esp
8010171d:	8b 5d 08             	mov    0x8(%ebp),%ebx
  iunlock(ip);
80101720:	53                   	push   %ebx
80101721:	e8 0b ff ff ff       	call   80101631 <iunlock>
  iput(ip);
80101726:	89 1c 24             	mov    %ebx,(%esp)
80101729:	e8 48 ff ff ff       	call   80101676 <iput>
}
8010172e:	83 c4 10             	add    $0x10,%esp
80101731:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101734:	c9                   	leave  
80101735:	c3                   	ret    

80101736 <stati>:
{
80101736:	55                   	push   %ebp
80101737:	89 e5                	mov    %esp,%ebp
80101739:	8b 55 08             	mov    0x8(%ebp),%edx
8010173c:	8b 45 0c             	mov    0xc(%ebp),%eax
  st->dev = ip->dev;
8010173f:	8b 0a                	mov    (%edx),%ecx
80101741:	89 48 04             	mov    %ecx,0x4(%eax)
  st->ino = ip->inum;
80101744:	8b 4a 04             	mov    0x4(%edx),%ecx
80101747:	89 48 08             	mov    %ecx,0x8(%eax)
  st->type = ip->type;
8010174a:	0f b7 4a 50          	movzwl 0x50(%edx),%ecx
8010174e:	66 89 08             	mov    %cx,(%eax)
  st->nlink = ip->nlink;
80101751:	0f b7 4a 56          	movzwl 0x56(%edx),%ecx
80101755:	66 89 48 0c          	mov    %cx,0xc(%eax)
  st->size = ip->size;
80101759:	8b 52 58             	mov    0x58(%edx),%edx
8010175c:	89 50 10             	mov    %edx,0x10(%eax)
}
8010175f:	5d                   	pop    %ebp
80101760:	c3                   	ret    

80101761 <readi>:
{
80101761:	55                   	push   %ebp
80101762:	89 e5                	mov    %esp,%ebp
80101764:	57                   	push   %edi
80101765:	56                   	push   %esi
80101766:	53                   	push   %ebx
80101767:	83 ec 1c             	sub    $0x1c,%esp
8010176a:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010176d:	8b 45 08             	mov    0x8(%ebp),%eax
80101770:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101775:	74 2c                	je     801017a3 <readi+0x42>
  if(off > ip->size || off + n < off)
80101777:	8b 45 08             	mov    0x8(%ebp),%eax
8010177a:	8b 40 58             	mov    0x58(%eax),%eax
8010177d:	39 f8                	cmp    %edi,%eax
8010177f:	0f 82 cb 00 00 00    	jb     80101850 <readi+0xef>
80101785:	89 fa                	mov    %edi,%edx
80101787:	03 55 14             	add    0x14(%ebp),%edx
8010178a:	0f 82 c7 00 00 00    	jb     80101857 <readi+0xf6>
  if(off + n > ip->size)
80101790:	39 d0                	cmp    %edx,%eax
80101792:	73 05                	jae    80101799 <readi+0x38>
    n = ip->size - off;
80101794:	29 f8                	sub    %edi,%eax
80101796:	89 45 14             	mov    %eax,0x14(%ebp)
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101799:	be 00 00 00 00       	mov    $0x0,%esi
8010179e:	e9 8f 00 00 00       	jmp    80101832 <readi+0xd1>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801017a3:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801017a7:	66 83 f8 09          	cmp    $0x9,%ax
801017ab:	0f 87 91 00 00 00    	ja     80101842 <readi+0xe1>
801017b1:	98                   	cwtl   
801017b2:	8b 04 c5 00 f9 10 80 	mov    -0x7fef0700(,%eax,8),%eax
801017b9:	85 c0                	test   %eax,%eax
801017bb:	0f 84 88 00 00 00    	je     80101849 <readi+0xe8>
    return devsw[ip->major].read(ip, dst, n);
801017c1:	83 ec 04             	sub    $0x4,%esp
801017c4:	ff 75 14             	push   0x14(%ebp)
801017c7:	ff 75 0c             	push   0xc(%ebp)
801017ca:	ff 75 08             	push   0x8(%ebp)
801017cd:	ff d0                	call   *%eax
801017cf:	83 c4 10             	add    $0x10,%esp
801017d2:	eb 66                	jmp    8010183a <readi+0xd9>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801017d4:	89 fa                	mov    %edi,%edx
801017d6:	c1 ea 09             	shr    $0x9,%edx
801017d9:	8b 45 08             	mov    0x8(%ebp),%eax
801017dc:	e8 70 f9 ff ff       	call   80101151 <bmap>
801017e1:	83 ec 08             	sub    $0x8,%esp
801017e4:	50                   	push   %eax
801017e5:	8b 45 08             	mov    0x8(%ebp),%eax
801017e8:	ff 30                	push   (%eax)
801017ea:	e8 7d e9 ff ff       	call   8010016c <bread>
801017ef:	89 c1                	mov    %eax,%ecx
    m = min(n - tot, BSIZE - off%BSIZE);
801017f1:	89 f8                	mov    %edi,%eax
801017f3:	25 ff 01 00 00       	and    $0x1ff,%eax
801017f8:	bb 00 02 00 00       	mov    $0x200,%ebx
801017fd:	29 c3                	sub    %eax,%ebx
801017ff:	8b 55 14             	mov    0x14(%ebp),%edx
80101802:	29 f2                	sub    %esi,%edx
80101804:	39 d3                	cmp    %edx,%ebx
80101806:	0f 47 da             	cmova  %edx,%ebx
    memmove(dst, bp->data + off%BSIZE, m);
80101809:	83 c4 0c             	add    $0xc,%esp
8010180c:	53                   	push   %ebx
8010180d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
80101810:	8d 44 01 5c          	lea    0x5c(%ecx,%eax,1),%eax
80101814:	50                   	push   %eax
80101815:	ff 75 0c             	push   0xc(%ebp)
80101818:	e8 87 25 00 00       	call   80103da4 <memmove>
    brelse(bp);
8010181d:	83 c4 04             	add    $0x4,%esp
80101820:	ff 75 e4             	push   -0x1c(%ebp)
80101823:	e8 ad e9 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101828:	01 de                	add    %ebx,%esi
8010182a:	01 df                	add    %ebx,%edi
8010182c:	01 5d 0c             	add    %ebx,0xc(%ebp)
8010182f:	83 c4 10             	add    $0x10,%esp
80101832:	39 75 14             	cmp    %esi,0x14(%ebp)
80101835:	77 9d                	ja     801017d4 <readi+0x73>
  return n;
80101837:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010183a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010183d:	5b                   	pop    %ebx
8010183e:	5e                   	pop    %esi
8010183f:	5f                   	pop    %edi
80101840:	5d                   	pop    %ebp
80101841:	c3                   	ret    
      return -1;
80101842:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101847:	eb f1                	jmp    8010183a <readi+0xd9>
80101849:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010184e:	eb ea                	jmp    8010183a <readi+0xd9>
    return -1;
80101850:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101855:	eb e3                	jmp    8010183a <readi+0xd9>
80101857:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010185c:	eb dc                	jmp    8010183a <readi+0xd9>

8010185e <writei>:
{
8010185e:	55                   	push   %ebp
8010185f:	89 e5                	mov    %esp,%ebp
80101861:	57                   	push   %edi
80101862:	56                   	push   %esi
80101863:	53                   	push   %ebx
80101864:	83 ec 1c             	sub    $0x1c,%esp
80101867:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(ip->type == T_DEV){
8010186a:	8b 45 08             	mov    0x8(%ebp),%eax
8010186d:	66 83 78 50 03       	cmpw   $0x3,0x50(%eax)
80101872:	74 2e                	je     801018a2 <writei+0x44>
  if(off > ip->size || off + n < off)
80101874:	8b 45 08             	mov    0x8(%ebp),%eax
80101877:	39 78 58             	cmp    %edi,0x58(%eax)
8010187a:	0f 82 f5 00 00 00    	jb     80101975 <writei+0x117>
80101880:	89 f8                	mov    %edi,%eax
80101882:	03 45 14             	add    0x14(%ebp),%eax
80101885:	0f 82 f1 00 00 00    	jb     8010197c <writei+0x11e>
  if(off + n > MAXFILE*BSIZE)
8010188b:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101890:	0f 87 ed 00 00 00    	ja     80101983 <writei+0x125>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101896:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010189d:	e9 93 00 00 00       	jmp    80101935 <writei+0xd7>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
801018a2:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801018a6:	66 83 f8 09          	cmp    $0x9,%ax
801018aa:	0f 87 b7 00 00 00    	ja     80101967 <writei+0x109>
801018b0:	98                   	cwtl   
801018b1:	8b 04 c5 04 f9 10 80 	mov    -0x7fef06fc(,%eax,8),%eax
801018b8:	85 c0                	test   %eax,%eax
801018ba:	0f 84 ae 00 00 00    	je     8010196e <writei+0x110>
    return devsw[ip->major].write(ip, src, n);
801018c0:	83 ec 04             	sub    $0x4,%esp
801018c3:	ff 75 14             	push   0x14(%ebp)
801018c6:	ff 75 0c             	push   0xc(%ebp)
801018c9:	ff 75 08             	push   0x8(%ebp)
801018cc:	ff d0                	call   *%eax
801018ce:	83 c4 10             	add    $0x10,%esp
801018d1:	eb 7b                	jmp    8010194e <writei+0xf0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801018d3:	89 fa                	mov    %edi,%edx
801018d5:	c1 ea 09             	shr    $0x9,%edx
801018d8:	8b 45 08             	mov    0x8(%ebp),%eax
801018db:	e8 71 f8 ff ff       	call   80101151 <bmap>
801018e0:	83 ec 08             	sub    $0x8,%esp
801018e3:	50                   	push   %eax
801018e4:	8b 45 08             	mov    0x8(%ebp),%eax
801018e7:	ff 30                	push   (%eax)
801018e9:	e8 7e e8 ff ff       	call   8010016c <bread>
801018ee:	89 c6                	mov    %eax,%esi
    m = min(n - tot, BSIZE - off%BSIZE);
801018f0:	89 f8                	mov    %edi,%eax
801018f2:	25 ff 01 00 00       	and    $0x1ff,%eax
801018f7:	bb 00 02 00 00       	mov    $0x200,%ebx
801018fc:	29 c3                	sub    %eax,%ebx
801018fe:	8b 55 14             	mov    0x14(%ebp),%edx
80101901:	2b 55 e4             	sub    -0x1c(%ebp),%edx
80101904:	39 d3                	cmp    %edx,%ebx
80101906:	0f 47 da             	cmova  %edx,%ebx
    memmove(bp->data + off%BSIZE, src, m);
80101909:	83 c4 0c             	add    $0xc,%esp
8010190c:	53                   	push   %ebx
8010190d:	ff 75 0c             	push   0xc(%ebp)
80101910:	8d 44 06 5c          	lea    0x5c(%esi,%eax,1),%eax
80101914:	50                   	push   %eax
80101915:	e8 8a 24 00 00       	call   80103da4 <memmove>
    log_write(bp);
8010191a:	89 34 24             	mov    %esi,(%esp)
8010191d:	e8 85 0f 00 00       	call   801028a7 <log_write>
    brelse(bp);
80101922:	89 34 24             	mov    %esi,(%esp)
80101925:	e8 ab e8 ff ff       	call   801001d5 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010192a:	01 5d e4             	add    %ebx,-0x1c(%ebp)
8010192d:	01 df                	add    %ebx,%edi
8010192f:	01 5d 0c             	add    %ebx,0xc(%ebp)
80101932:	83 c4 10             	add    $0x10,%esp
80101935:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101938:	3b 45 14             	cmp    0x14(%ebp),%eax
8010193b:	72 96                	jb     801018d3 <writei+0x75>
  if(n > 0 && off > ip->size){
8010193d:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80101941:	74 08                	je     8010194b <writei+0xed>
80101943:	8b 45 08             	mov    0x8(%ebp),%eax
80101946:	39 78 58             	cmp    %edi,0x58(%eax)
80101949:	72 0b                	jb     80101956 <writei+0xf8>
  return n;
8010194b:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010194e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101951:	5b                   	pop    %ebx
80101952:	5e                   	pop    %esi
80101953:	5f                   	pop    %edi
80101954:	5d                   	pop    %ebp
80101955:	c3                   	ret    
    ip->size = off;
80101956:	89 78 58             	mov    %edi,0x58(%eax)
    iupdate(ip);
80101959:	83 ec 0c             	sub    $0xc,%esp
8010195c:	50                   	push   %eax
8010195d:	e8 ac fa ff ff       	call   8010140e <iupdate>
80101962:	83 c4 10             	add    $0x10,%esp
80101965:	eb e4                	jmp    8010194b <writei+0xed>
      return -1;
80101967:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010196c:	eb e0                	jmp    8010194e <writei+0xf0>
8010196e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101973:	eb d9                	jmp    8010194e <writei+0xf0>
    return -1;
80101975:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010197a:	eb d2                	jmp    8010194e <writei+0xf0>
8010197c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101981:	eb cb                	jmp    8010194e <writei+0xf0>
    return -1;
80101983:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101988:	eb c4                	jmp    8010194e <writei+0xf0>

8010198a <namecmp>:
{
8010198a:	55                   	push   %ebp
8010198b:	89 e5                	mov    %esp,%ebp
8010198d:	83 ec 0c             	sub    $0xc,%esp
  return strncmp(s, t, DIRSIZ);
80101990:	6a 0e                	push   $0xe
80101992:	ff 75 0c             	push   0xc(%ebp)
80101995:	ff 75 08             	push   0x8(%ebp)
80101998:	e8 73 24 00 00       	call   80103e10 <strncmp>
}
8010199d:	c9                   	leave  
8010199e:	c3                   	ret    

8010199f <dirlookup>:
{
8010199f:	55                   	push   %ebp
801019a0:	89 e5                	mov    %esp,%ebp
801019a2:	57                   	push   %edi
801019a3:	56                   	push   %esi
801019a4:	53                   	push   %ebx
801019a5:	83 ec 1c             	sub    $0x1c,%esp
801019a8:	8b 75 08             	mov    0x8(%ebp),%esi
801019ab:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if(dp->type != T_DIR)
801019ae:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801019b3:	75 07                	jne    801019bc <dirlookup+0x1d>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019b5:	bb 00 00 00 00       	mov    $0x0,%ebx
801019ba:	eb 1d                	jmp    801019d9 <dirlookup+0x3a>
    panic("dirlookup not DIR");
801019bc:	83 ec 0c             	sub    $0xc,%esp
801019bf:	68 a7 69 10 80       	push   $0x801069a7
801019c4:	e8 7f e9 ff ff       	call   80100348 <panic>
      panic("dirlookup read");
801019c9:	83 ec 0c             	sub    $0xc,%esp
801019cc:	68 b9 69 10 80       	push   $0x801069b9
801019d1:	e8 72 e9 ff ff       	call   80100348 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
801019d6:	83 c3 10             	add    $0x10,%ebx
801019d9:	39 5e 58             	cmp    %ebx,0x58(%esi)
801019dc:	76 48                	jbe    80101a26 <dirlookup+0x87>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801019de:	6a 10                	push   $0x10
801019e0:	53                   	push   %ebx
801019e1:	8d 45 d8             	lea    -0x28(%ebp),%eax
801019e4:	50                   	push   %eax
801019e5:	56                   	push   %esi
801019e6:	e8 76 fd ff ff       	call   80101761 <readi>
801019eb:	83 c4 10             	add    $0x10,%esp
801019ee:	83 f8 10             	cmp    $0x10,%eax
801019f1:	75 d6                	jne    801019c9 <dirlookup+0x2a>
    if(de.inum == 0)
801019f3:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
801019f8:	74 dc                	je     801019d6 <dirlookup+0x37>
    if(namecmp(name, de.name) == 0){
801019fa:	83 ec 08             	sub    $0x8,%esp
801019fd:	8d 45 da             	lea    -0x26(%ebp),%eax
80101a00:	50                   	push   %eax
80101a01:	57                   	push   %edi
80101a02:	e8 83 ff ff ff       	call   8010198a <namecmp>
80101a07:	83 c4 10             	add    $0x10,%esp
80101a0a:	85 c0                	test   %eax,%eax
80101a0c:	75 c8                	jne    801019d6 <dirlookup+0x37>
      if(poff)
80101a0e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80101a12:	74 05                	je     80101a19 <dirlookup+0x7a>
        *poff = off;
80101a14:	8b 45 10             	mov    0x10(%ebp),%eax
80101a17:	89 18                	mov    %ebx,(%eax)
      inum = de.inum;
80101a19:	0f b7 55 d8          	movzwl -0x28(%ebp),%edx
      return iget(dp->dev, inum);
80101a1d:	8b 06                	mov    (%esi),%eax
80101a1f:	e8 d3 f7 ff ff       	call   801011f7 <iget>
80101a24:	eb 05                	jmp    80101a2b <dirlookup+0x8c>
  return 0;
80101a26:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101a2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a2e:	5b                   	pop    %ebx
80101a2f:	5e                   	pop    %esi
80101a30:	5f                   	pop    %edi
80101a31:	5d                   	pop    %ebp
80101a32:	c3                   	ret    

80101a33 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80101a33:	55                   	push   %ebp
80101a34:	89 e5                	mov    %esp,%ebp
80101a36:	57                   	push   %edi
80101a37:	56                   	push   %esi
80101a38:	53                   	push   %ebx
80101a39:	83 ec 1c             	sub    $0x1c,%esp
80101a3c:	89 c3                	mov    %eax,%ebx
80101a3e:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101a41:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
  struct inode *ip, *next;

  if(*path == '/')
80101a44:	80 38 2f             	cmpb   $0x2f,(%eax)
80101a47:	74 17                	je     80101a60 <namex+0x2d>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
80101a49:	e8 cd 17 00 00       	call   8010321b <myproc>
80101a4e:	83 ec 0c             	sub    $0xc,%esp
80101a51:	ff 70 68             	push   0x68(%eax)
80101a54:	e8 e6 fa ff ff       	call   8010153f <idup>
80101a59:	89 c6                	mov    %eax,%esi
80101a5b:	83 c4 10             	add    $0x10,%esp
80101a5e:	eb 53                	jmp    80101ab3 <namex+0x80>
    ip = iget(ROOTDEV, ROOTINO);
80101a60:	ba 01 00 00 00       	mov    $0x1,%edx
80101a65:	b8 01 00 00 00       	mov    $0x1,%eax
80101a6a:	e8 88 f7 ff ff       	call   801011f7 <iget>
80101a6f:	89 c6                	mov    %eax,%esi
80101a71:	eb 40                	jmp    80101ab3 <namex+0x80>

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
      iunlockput(ip);
80101a73:	83 ec 0c             	sub    $0xc,%esp
80101a76:	56                   	push   %esi
80101a77:	e8 9a fc ff ff       	call   80101716 <iunlockput>
      return 0;
80101a7c:	83 c4 10             	add    $0x10,%esp
80101a7f:	be 00 00 00 00       	mov    $0x0,%esi
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
80101a84:	89 f0                	mov    %esi,%eax
80101a86:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101a89:	5b                   	pop    %ebx
80101a8a:	5e                   	pop    %esi
80101a8b:	5f                   	pop    %edi
80101a8c:	5d                   	pop    %ebp
80101a8d:	c3                   	ret    
    if((next = dirlookup(ip, name, 0)) == 0){
80101a8e:	83 ec 04             	sub    $0x4,%esp
80101a91:	6a 00                	push   $0x0
80101a93:	ff 75 e4             	push   -0x1c(%ebp)
80101a96:	56                   	push   %esi
80101a97:	e8 03 ff ff ff       	call   8010199f <dirlookup>
80101a9c:	89 c7                	mov    %eax,%edi
80101a9e:	83 c4 10             	add    $0x10,%esp
80101aa1:	85 c0                	test   %eax,%eax
80101aa3:	74 4a                	je     80101aef <namex+0xbc>
    iunlockput(ip);
80101aa5:	83 ec 0c             	sub    $0xc,%esp
80101aa8:	56                   	push   %esi
80101aa9:	e8 68 fc ff ff       	call   80101716 <iunlockput>
80101aae:	83 c4 10             	add    $0x10,%esp
    ip = next;
80101ab1:	89 fe                	mov    %edi,%esi
  while((path = skipelem(path, name)) != 0){
80101ab3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80101ab6:	89 d8                	mov    %ebx,%eax
80101ab8:	e8 85 f4 ff ff       	call   80100f42 <skipelem>
80101abd:	89 c3                	mov    %eax,%ebx
80101abf:	85 c0                	test   %eax,%eax
80101ac1:	74 3c                	je     80101aff <namex+0xcc>
    ilock(ip);
80101ac3:	83 ec 0c             	sub    $0xc,%esp
80101ac6:	56                   	push   %esi
80101ac7:	e8 a3 fa ff ff       	call   8010156f <ilock>
    if(ip->type != T_DIR){
80101acc:	83 c4 10             	add    $0x10,%esp
80101acf:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
80101ad4:	75 9d                	jne    80101a73 <namex+0x40>
    if(nameiparent && *path == '\0'){
80101ad6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101ada:	74 b2                	je     80101a8e <namex+0x5b>
80101adc:	80 3b 00             	cmpb   $0x0,(%ebx)
80101adf:	75 ad                	jne    80101a8e <namex+0x5b>
      iunlock(ip);
80101ae1:	83 ec 0c             	sub    $0xc,%esp
80101ae4:	56                   	push   %esi
80101ae5:	e8 47 fb ff ff       	call   80101631 <iunlock>
      return ip;
80101aea:	83 c4 10             	add    $0x10,%esp
80101aed:	eb 95                	jmp    80101a84 <namex+0x51>
      iunlockput(ip);
80101aef:	83 ec 0c             	sub    $0xc,%esp
80101af2:	56                   	push   %esi
80101af3:	e8 1e fc ff ff       	call   80101716 <iunlockput>
      return 0;
80101af8:	83 c4 10             	add    $0x10,%esp
80101afb:	89 fe                	mov    %edi,%esi
80101afd:	eb 85                	jmp    80101a84 <namex+0x51>
  if(nameiparent){
80101aff:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101b03:	0f 84 7b ff ff ff    	je     80101a84 <namex+0x51>
    iput(ip);
80101b09:	83 ec 0c             	sub    $0xc,%esp
80101b0c:	56                   	push   %esi
80101b0d:	e8 64 fb ff ff       	call   80101676 <iput>
    return 0;
80101b12:	83 c4 10             	add    $0x10,%esp
80101b15:	89 de                	mov    %ebx,%esi
80101b17:	e9 68 ff ff ff       	jmp    80101a84 <namex+0x51>

80101b1c <dirlink>:
{
80101b1c:	55                   	push   %ebp
80101b1d:	89 e5                	mov    %esp,%ebp
80101b1f:	57                   	push   %edi
80101b20:	56                   	push   %esi
80101b21:	53                   	push   %ebx
80101b22:	83 ec 20             	sub    $0x20,%esp
80101b25:	8b 5d 08             	mov    0x8(%ebp),%ebx
80101b28:	8b 7d 0c             	mov    0xc(%ebp),%edi
  if((ip = dirlookup(dp, name, 0)) != 0){
80101b2b:	6a 00                	push   $0x0
80101b2d:	57                   	push   %edi
80101b2e:	53                   	push   %ebx
80101b2f:	e8 6b fe ff ff       	call   8010199f <dirlookup>
80101b34:	83 c4 10             	add    $0x10,%esp
80101b37:	85 c0                	test   %eax,%eax
80101b39:	75 2d                	jne    80101b68 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b3b:	b8 00 00 00 00       	mov    $0x0,%eax
80101b40:	89 c6                	mov    %eax,%esi
80101b42:	39 43 58             	cmp    %eax,0x58(%ebx)
80101b45:	76 41                	jbe    80101b88 <dirlink+0x6c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101b47:	6a 10                	push   $0x10
80101b49:	50                   	push   %eax
80101b4a:	8d 45 d8             	lea    -0x28(%ebp),%eax
80101b4d:	50                   	push   %eax
80101b4e:	53                   	push   %ebx
80101b4f:	e8 0d fc ff ff       	call   80101761 <readi>
80101b54:	83 c4 10             	add    $0x10,%esp
80101b57:	83 f8 10             	cmp    $0x10,%eax
80101b5a:	75 1f                	jne    80101b7b <dirlink+0x5f>
    if(de.inum == 0)
80101b5c:	66 83 7d d8 00       	cmpw   $0x0,-0x28(%ebp)
80101b61:	74 25                	je     80101b88 <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
80101b63:	8d 46 10             	lea    0x10(%esi),%eax
80101b66:	eb d8                	jmp    80101b40 <dirlink+0x24>
    iput(ip);
80101b68:	83 ec 0c             	sub    $0xc,%esp
80101b6b:	50                   	push   %eax
80101b6c:	e8 05 fb ff ff       	call   80101676 <iput>
    return -1;
80101b71:	83 c4 10             	add    $0x10,%esp
80101b74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101b79:	eb 3d                	jmp    80101bb8 <dirlink+0x9c>
      panic("dirlink read");
80101b7b:	83 ec 0c             	sub    $0xc,%esp
80101b7e:	68 c8 69 10 80       	push   $0x801069c8
80101b83:	e8 c0 e7 ff ff       	call   80100348 <panic>
  strncpy(de.name, name, DIRSIZ);
80101b88:	83 ec 04             	sub    $0x4,%esp
80101b8b:	6a 0e                	push   $0xe
80101b8d:	57                   	push   %edi
80101b8e:	8d 7d d8             	lea    -0x28(%ebp),%edi
80101b91:	8d 45 da             	lea    -0x26(%ebp),%eax
80101b94:	50                   	push   %eax
80101b95:	e8 b5 22 00 00       	call   80103e4f <strncpy>
  de.inum = inum;
80101b9a:	8b 45 10             	mov    0x10(%ebp),%eax
80101b9d:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80101ba1:	6a 10                	push   $0x10
80101ba3:	56                   	push   %esi
80101ba4:	57                   	push   %edi
80101ba5:	53                   	push   %ebx
80101ba6:	e8 b3 fc ff ff       	call   8010185e <writei>
80101bab:	83 c4 20             	add    $0x20,%esp
80101bae:	83 f8 10             	cmp    $0x10,%eax
80101bb1:	75 0d                	jne    80101bc0 <dirlink+0xa4>
  return 0;
80101bb3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101bb8:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101bbb:	5b                   	pop    %ebx
80101bbc:	5e                   	pop    %esi
80101bbd:	5f                   	pop    %edi
80101bbe:	5d                   	pop    %ebp
80101bbf:	c3                   	ret    
    panic("dirlink");
80101bc0:	83 ec 0c             	sub    $0xc,%esp
80101bc3:	68 c0 6f 10 80       	push   $0x80106fc0
80101bc8:	e8 7b e7 ff ff       	call   80100348 <panic>

80101bcd <namei>:

struct inode*
namei(char *path)
{
80101bcd:	55                   	push   %ebp
80101bce:	89 e5                	mov    %esp,%ebp
80101bd0:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80101bd3:	8d 4d ea             	lea    -0x16(%ebp),%ecx
80101bd6:	ba 00 00 00 00       	mov    $0x0,%edx
80101bdb:	8b 45 08             	mov    0x8(%ebp),%eax
80101bde:	e8 50 fe ff ff       	call   80101a33 <namex>
}
80101be3:	c9                   	leave  
80101be4:	c3                   	ret    

80101be5 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80101be5:	55                   	push   %ebp
80101be6:	89 e5                	mov    %esp,%ebp
80101be8:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80101beb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80101bee:	ba 01 00 00 00       	mov    $0x1,%edx
80101bf3:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf6:	e8 38 fe ff ff       	call   80101a33 <namex>
}
80101bfb:	c9                   	leave  
80101bfc:	c3                   	ret    

80101bfd <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80101bfd:	89 c1                	mov    %eax,%ecx
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101bff:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101c04:	ec                   	in     (%dx),%al
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80101c05:	89 c2                	mov    %eax,%edx
80101c07:	83 e2 c0             	and    $0xffffffc0,%edx
80101c0a:	80 fa 40             	cmp    $0x40,%dl
80101c0d:	75 f0                	jne    80101bff <idewait+0x2>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80101c0f:	85 c9                	test   %ecx,%ecx
80101c11:	74 09                	je     80101c1c <idewait+0x1f>
80101c13:	a8 21                	test   $0x21,%al
80101c15:	75 08                	jne    80101c1f <idewait+0x22>
    return -1;
  return 0;
80101c17:	b9 00 00 00 00       	mov    $0x0,%ecx
}
80101c1c:	89 c8                	mov    %ecx,%eax
80101c1e:	c3                   	ret    
    return -1;
80101c1f:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
80101c24:	eb f6                	jmp    80101c1c <idewait+0x1f>

80101c26 <idestart>:
}

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80101c26:	55                   	push   %ebp
80101c27:	89 e5                	mov    %esp,%ebp
80101c29:	56                   	push   %esi
80101c2a:	53                   	push   %ebx
  if(b == 0)
80101c2b:	85 c0                	test   %eax,%eax
80101c2d:	0f 84 8f 00 00 00    	je     80101cc2 <idestart+0x9c>
80101c33:	89 c6                	mov    %eax,%esi
    panic("idestart");
  if(b->blockno >= FSSIZE)
80101c35:	8b 58 08             	mov    0x8(%eax),%ebx
80101c38:	81 fb 1f 4e 00 00    	cmp    $0x4e1f,%ebx
80101c3e:	0f 87 8b 00 00 00    	ja     80101ccf <idestart+0xa9>
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;

  if (sector_per_block > 7) panic("idestart");

  idewait(0);
80101c44:	b8 00 00 00 00       	mov    $0x0,%eax
80101c49:	e8 af ff ff ff       	call   80101bfd <idewait>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101c4e:	b8 00 00 00 00       	mov    $0x0,%eax
80101c53:	ba f6 03 00 00       	mov    $0x3f6,%edx
80101c58:	ee                   	out    %al,(%dx)
80101c59:	b8 01 00 00 00       	mov    $0x1,%eax
80101c5e:	ba f2 01 00 00       	mov    $0x1f2,%edx
80101c63:	ee                   	out    %al,(%dx)
80101c64:	ba f3 01 00 00       	mov    $0x1f3,%edx
80101c69:	89 d8                	mov    %ebx,%eax
80101c6b:	ee                   	out    %al,(%dx)
  outb(0x3f6, 0);  // generate interrupt
  outb(0x1f2, sector_per_block);  // number of sectors
  outb(0x1f3, sector & 0xff);
  outb(0x1f4, (sector >> 8) & 0xff);
80101c6c:	0f b6 c7             	movzbl %bh,%eax
80101c6f:	ba f4 01 00 00       	mov    $0x1f4,%edx
80101c74:	ee                   	out    %al,(%dx)
  outb(0x1f5, (sector >> 16) & 0xff);
80101c75:	89 d8                	mov    %ebx,%eax
80101c77:	c1 f8 10             	sar    $0x10,%eax
80101c7a:	ba f5 01 00 00       	mov    $0x1f5,%edx
80101c7f:	ee                   	out    %al,(%dx)
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
80101c80:	0f b6 46 04          	movzbl 0x4(%esi),%eax
80101c84:	c1 e0 04             	shl    $0x4,%eax
80101c87:	83 e0 10             	and    $0x10,%eax
80101c8a:	c1 fb 18             	sar    $0x18,%ebx
80101c8d:	83 e3 0f             	and    $0xf,%ebx
80101c90:	09 d8                	or     %ebx,%eax
80101c92:	83 c8 e0             	or     $0xffffffe0,%eax
80101c95:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101c9a:	ee                   	out    %al,(%dx)
  if(b->flags & B_DIRTY){
80101c9b:	f6 06 04             	testb  $0x4,(%esi)
80101c9e:	74 3c                	je     80101cdc <idestart+0xb6>
80101ca0:	b8 30 00 00 00       	mov    $0x30,%eax
80101ca5:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101caa:	ee                   	out    %al,(%dx)
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
80101cab:	83 c6 5c             	add    $0x5c,%esi
  asm volatile("cld; rep outsl" :
80101cae:	b9 80 00 00 00       	mov    $0x80,%ecx
80101cb3:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101cb8:	fc                   	cld    
80101cb9:	f3 6f                	rep outsl %ds:(%esi),(%dx)
  } else {
    outb(0x1f7, read_cmd);
  }
}
80101cbb:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101cbe:	5b                   	pop    %ebx
80101cbf:	5e                   	pop    %esi
80101cc0:	5d                   	pop    %ebp
80101cc1:	c3                   	ret    
    panic("idestart");
80101cc2:	83 ec 0c             	sub    $0xc,%esp
80101cc5:	68 2b 6a 10 80       	push   $0x80106a2b
80101cca:	e8 79 e6 ff ff       	call   80100348 <panic>
    panic("incorrect blockno");
80101ccf:	83 ec 0c             	sub    $0xc,%esp
80101cd2:	68 34 6a 10 80       	push   $0x80106a34
80101cd7:	e8 6c e6 ff ff       	call   80100348 <panic>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101cdc:	b8 20 00 00 00       	mov    $0x20,%eax
80101ce1:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101ce6:	ee                   	out    %al,(%dx)
}
80101ce7:	eb d2                	jmp    80101cbb <idestart+0x95>

80101ce9 <ideinit>:
{
80101ce9:	55                   	push   %ebp
80101cea:	89 e5                	mov    %esp,%ebp
80101cec:	83 ec 10             	sub    $0x10,%esp
  initlock(&idelock, "ide");
80101cef:	68 46 6a 10 80       	push   $0x80106a46
80101cf4:	68 00 16 11 80       	push   $0x80111600
80101cf9:	e8 46 1e 00 00       	call   80103b44 <initlock>
  ioapicenable(IRQ_IDE, ncpu - 1);
80101cfe:	83 c4 08             	add    $0x8,%esp
80101d01:	a1 84 17 11 80       	mov    0x80111784,%eax
80101d06:	83 e8 01             	sub    $0x1,%eax
80101d09:	50                   	push   %eax
80101d0a:	6a 0e                	push   $0xe
80101d0c:	e8 50 02 00 00       	call   80101f61 <ioapicenable>
  idewait(0);
80101d11:	b8 00 00 00 00       	mov    $0x0,%eax
80101d16:	e8 e2 fe ff ff       	call   80101bfd <idewait>
80101d1b:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
80101d20:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d25:	ee                   	out    %al,(%dx)
  for(i=0; i<1000; i++){
80101d26:	83 c4 10             	add    $0x10,%esp
80101d29:	b9 00 00 00 00       	mov    $0x0,%ecx
80101d2e:	81 f9 e7 03 00 00    	cmp    $0x3e7,%ecx
80101d34:	7f 19                	jg     80101d4f <ideinit+0x66>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80101d36:	ba f7 01 00 00       	mov    $0x1f7,%edx
80101d3b:	ec                   	in     (%dx),%al
    if(inb(0x1f7) != 0){
80101d3c:	84 c0                	test   %al,%al
80101d3e:	75 05                	jne    80101d45 <ideinit+0x5c>
  for(i=0; i<1000; i++){
80101d40:	83 c1 01             	add    $0x1,%ecx
80101d43:	eb e9                	jmp    80101d2e <ideinit+0x45>
      havedisk1 = 1;
80101d45:	c7 05 e0 15 11 80 01 	movl   $0x1,0x801115e0
80101d4c:	00 00 00 
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80101d4f:	b8 e0 ff ff ff       	mov    $0xffffffe0,%eax
80101d54:	ba f6 01 00 00       	mov    $0x1f6,%edx
80101d59:	ee                   	out    %al,(%dx)
}
80101d5a:	c9                   	leave  
80101d5b:	c3                   	ret    

80101d5c <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80101d5c:	55                   	push   %ebp
80101d5d:	89 e5                	mov    %esp,%ebp
80101d5f:	57                   	push   %edi
80101d60:	53                   	push   %ebx
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80101d61:	83 ec 0c             	sub    $0xc,%esp
80101d64:	68 00 16 11 80       	push   $0x80111600
80101d69:	e8 12 1f 00 00       	call   80103c80 <acquire>

  if((b = idequeue) == 0){
80101d6e:	8b 1d e4 15 11 80    	mov    0x801115e4,%ebx
80101d74:	83 c4 10             	add    $0x10,%esp
80101d77:	85 db                	test   %ebx,%ebx
80101d79:	74 4a                	je     80101dc5 <ideintr+0x69>
    release(&idelock);
    return;
  }
  idequeue = b->qnext;
80101d7b:	8b 43 58             	mov    0x58(%ebx),%eax
80101d7e:	a3 e4 15 11 80       	mov    %eax,0x801115e4

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101d83:	f6 03 04             	testb  $0x4,(%ebx)
80101d86:	74 4f                	je     80101dd7 <ideintr+0x7b>
    insl(0x1f0, b->data, BSIZE/4);

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80101d88:	8b 03                	mov    (%ebx),%eax
80101d8a:	83 c8 02             	or     $0x2,%eax
80101d8d:	89 03                	mov    %eax,(%ebx)
  b->flags &= ~B_DIRTY;
80101d8f:	83 e0 fb             	and    $0xfffffffb,%eax
80101d92:	89 03                	mov    %eax,(%ebx)
  wakeup(b);
80101d94:	83 ec 0c             	sub    $0xc,%esp
80101d97:	53                   	push   %ebx
80101d98:	e8 48 1b 00 00       	call   801038e5 <wakeup>

  // Start disk on next buf in queue.
  if(idequeue != 0)
80101d9d:	a1 e4 15 11 80       	mov    0x801115e4,%eax
80101da2:	83 c4 10             	add    $0x10,%esp
80101da5:	85 c0                	test   %eax,%eax
80101da7:	74 05                	je     80101dae <ideintr+0x52>
    idestart(idequeue);
80101da9:	e8 78 fe ff ff       	call   80101c26 <idestart>

  release(&idelock);
80101dae:	83 ec 0c             	sub    $0xc,%esp
80101db1:	68 00 16 11 80       	push   $0x80111600
80101db6:	e8 2a 1f 00 00       	call   80103ce5 <release>
80101dbb:	83 c4 10             	add    $0x10,%esp
}
80101dbe:	8d 65 f8             	lea    -0x8(%ebp),%esp
80101dc1:	5b                   	pop    %ebx
80101dc2:	5f                   	pop    %edi
80101dc3:	5d                   	pop    %ebp
80101dc4:	c3                   	ret    
    release(&idelock);
80101dc5:	83 ec 0c             	sub    $0xc,%esp
80101dc8:	68 00 16 11 80       	push   $0x80111600
80101dcd:	e8 13 1f 00 00       	call   80103ce5 <release>
    return;
80101dd2:	83 c4 10             	add    $0x10,%esp
80101dd5:	eb e7                	jmp    80101dbe <ideintr+0x62>
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80101dd7:	b8 01 00 00 00       	mov    $0x1,%eax
80101ddc:	e8 1c fe ff ff       	call   80101bfd <idewait>
80101de1:	85 c0                	test   %eax,%eax
80101de3:	78 a3                	js     80101d88 <ideintr+0x2c>
    insl(0x1f0, b->data, BSIZE/4);
80101de5:	8d 7b 5c             	lea    0x5c(%ebx),%edi
  asm volatile("cld; rep insl" :
80101de8:	b9 80 00 00 00       	mov    $0x80,%ecx
80101ded:	ba f0 01 00 00       	mov    $0x1f0,%edx
80101df2:	fc                   	cld    
80101df3:	f3 6d                	rep insl (%dx),%es:(%edi)
}
80101df5:	eb 91                	jmp    80101d88 <ideintr+0x2c>

80101df7 <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80101df7:	55                   	push   %ebp
80101df8:	89 e5                	mov    %esp,%ebp
80101dfa:	53                   	push   %ebx
80101dfb:	83 ec 10             	sub    $0x10,%esp
80101dfe:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80101e01:	8d 43 0c             	lea    0xc(%ebx),%eax
80101e04:	50                   	push   %eax
80101e05:	e8 ec 1c 00 00       	call   80103af6 <holdingsleep>
80101e0a:	83 c4 10             	add    $0x10,%esp
80101e0d:	85 c0                	test   %eax,%eax
80101e0f:	74 37                	je     80101e48 <iderw+0x51>
    panic("iderw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80101e11:	8b 03                	mov    (%ebx),%eax
80101e13:	83 e0 06             	and    $0x6,%eax
80101e16:	83 f8 02             	cmp    $0x2,%eax
80101e19:	74 3a                	je     80101e55 <iderw+0x5e>
    panic("iderw: nothing to do");
  if(b->dev != 0 && !havedisk1)
80101e1b:	83 7b 04 00          	cmpl   $0x0,0x4(%ebx)
80101e1f:	74 09                	je     80101e2a <iderw+0x33>
80101e21:	83 3d e0 15 11 80 00 	cmpl   $0x0,0x801115e0
80101e28:	74 38                	je     80101e62 <iderw+0x6b>
    panic("iderw: ide disk 1 not present");

  acquire(&idelock);  //DOC:acquire-lock
80101e2a:	83 ec 0c             	sub    $0xc,%esp
80101e2d:	68 00 16 11 80       	push   $0x80111600
80101e32:	e8 49 1e 00 00       	call   80103c80 <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80101e37:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e3e:	83 c4 10             	add    $0x10,%esp
80101e41:	ba e4 15 11 80       	mov    $0x801115e4,%edx
80101e46:	eb 2a                	jmp    80101e72 <iderw+0x7b>
    panic("iderw: buf not locked");
80101e48:	83 ec 0c             	sub    $0xc,%esp
80101e4b:	68 4a 6a 10 80       	push   $0x80106a4a
80101e50:	e8 f3 e4 ff ff       	call   80100348 <panic>
    panic("iderw: nothing to do");
80101e55:	83 ec 0c             	sub    $0xc,%esp
80101e58:	68 60 6a 10 80       	push   $0x80106a60
80101e5d:	e8 e6 e4 ff ff       	call   80100348 <panic>
    panic("iderw: ide disk 1 not present");
80101e62:	83 ec 0c             	sub    $0xc,%esp
80101e65:	68 75 6a 10 80       	push   $0x80106a75
80101e6a:	e8 d9 e4 ff ff       	call   80100348 <panic>
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
80101e6f:	8d 50 58             	lea    0x58(%eax),%edx
80101e72:	8b 02                	mov    (%edx),%eax
80101e74:	85 c0                	test   %eax,%eax
80101e76:	75 f7                	jne    80101e6f <iderw+0x78>
    ;
  *pp = b;
80101e78:	89 1a                	mov    %ebx,(%edx)

  // Start disk if necessary.
  if(idequeue == b)
80101e7a:	39 1d e4 15 11 80    	cmp    %ebx,0x801115e4
80101e80:	75 1a                	jne    80101e9c <iderw+0xa5>
    idestart(b);
80101e82:	89 d8                	mov    %ebx,%eax
80101e84:	e8 9d fd ff ff       	call   80101c26 <idestart>
80101e89:	eb 11                	jmp    80101e9c <iderw+0xa5>

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
    sleep(b, &idelock);
80101e8b:	83 ec 08             	sub    $0x8,%esp
80101e8e:	68 00 16 11 80       	push   $0x80111600
80101e93:	53                   	push   %ebx
80101e94:	e8 e4 18 00 00       	call   8010377d <sleep>
80101e99:	83 c4 10             	add    $0x10,%esp
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80101e9c:	8b 03                	mov    (%ebx),%eax
80101e9e:	83 e0 06             	and    $0x6,%eax
80101ea1:	83 f8 02             	cmp    $0x2,%eax
80101ea4:	75 e5                	jne    80101e8b <iderw+0x94>
  }


  release(&idelock);
80101ea6:	83 ec 0c             	sub    $0xc,%esp
80101ea9:	68 00 16 11 80       	push   $0x80111600
80101eae:	e8 32 1e 00 00       	call   80103ce5 <release>
}
80101eb3:	83 c4 10             	add    $0x10,%esp
80101eb6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101eb9:	c9                   	leave  
80101eba:	c3                   	ret    

80101ebb <ioapicread>:
};

static uint
ioapicread(int reg)
{
  ioapic->reg = reg;
80101ebb:	8b 15 34 16 11 80    	mov    0x80111634,%edx
80101ec1:	89 02                	mov    %eax,(%edx)
  return ioapic->data;
80101ec3:	a1 34 16 11 80       	mov    0x80111634,%eax
80101ec8:	8b 40 10             	mov    0x10(%eax),%eax
}
80101ecb:	c3                   	ret    

80101ecc <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
  ioapic->reg = reg;
80101ecc:	8b 0d 34 16 11 80    	mov    0x80111634,%ecx
80101ed2:	89 01                	mov    %eax,(%ecx)
  ioapic->data = data;
80101ed4:	a1 34 16 11 80       	mov    0x80111634,%eax
80101ed9:	89 50 10             	mov    %edx,0x10(%eax)
}
80101edc:	c3                   	ret    

80101edd <ioapicinit>:

void
ioapicinit(void)
{
80101edd:	55                   	push   %ebp
80101ede:	89 e5                	mov    %esp,%ebp
80101ee0:	57                   	push   %edi
80101ee1:	56                   	push   %esi
80101ee2:	53                   	push   %ebx
80101ee3:	83 ec 0c             	sub    $0xc,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80101ee6:	c7 05 34 16 11 80 00 	movl   $0xfec00000,0x80111634
80101eed:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80101ef0:	b8 01 00 00 00       	mov    $0x1,%eax
80101ef5:	e8 c1 ff ff ff       	call   80101ebb <ioapicread>
80101efa:	c1 e8 10             	shr    $0x10,%eax
80101efd:	0f b6 f8             	movzbl %al,%edi
  id = ioapicread(REG_ID) >> 24;
80101f00:	b8 00 00 00 00       	mov    $0x0,%eax
80101f05:	e8 b1 ff ff ff       	call   80101ebb <ioapicread>
80101f0a:	c1 e8 18             	shr    $0x18,%eax
  if(id != ioapicid)
80101f0d:	0f b6 15 80 17 11 80 	movzbl 0x80111780,%edx
80101f14:	39 c2                	cmp    %eax,%edx
80101f16:	75 07                	jne    80101f1f <ioapicinit+0x42>
{
80101f18:	bb 00 00 00 00       	mov    $0x0,%ebx
80101f1d:	eb 36                	jmp    80101f55 <ioapicinit+0x78>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80101f1f:	83 ec 0c             	sub    $0xc,%esp
80101f22:	68 94 6a 10 80       	push   $0x80106a94
80101f27:	e8 db e6 ff ff       	call   80100607 <cprintf>
80101f2c:	83 c4 10             	add    $0x10,%esp
80101f2f:	eb e7                	jmp    80101f18 <ioapicinit+0x3b>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80101f31:	8d 53 20             	lea    0x20(%ebx),%edx
80101f34:	81 ca 00 00 01 00    	or     $0x10000,%edx
80101f3a:	8d 74 1b 10          	lea    0x10(%ebx,%ebx,1),%esi
80101f3e:	89 f0                	mov    %esi,%eax
80101f40:	e8 87 ff ff ff       	call   80101ecc <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80101f45:	8d 46 01             	lea    0x1(%esi),%eax
80101f48:	ba 00 00 00 00       	mov    $0x0,%edx
80101f4d:	e8 7a ff ff ff       	call   80101ecc <ioapicwrite>
  for(i = 0; i <= maxintr; i++){
80101f52:	83 c3 01             	add    $0x1,%ebx
80101f55:	39 fb                	cmp    %edi,%ebx
80101f57:	7e d8                	jle    80101f31 <ioapicinit+0x54>
  }
}
80101f59:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101f5c:	5b                   	pop    %ebx
80101f5d:	5e                   	pop    %esi
80101f5e:	5f                   	pop    %edi
80101f5f:	5d                   	pop    %ebp
80101f60:	c3                   	ret    

80101f61 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80101f61:	55                   	push   %ebp
80101f62:	89 e5                	mov    %esp,%ebp
80101f64:	53                   	push   %ebx
80101f65:	83 ec 04             	sub    $0x4,%esp
80101f68:	8b 45 08             	mov    0x8(%ebp),%eax
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80101f6b:	8d 50 20             	lea    0x20(%eax),%edx
80101f6e:	8d 5c 00 10          	lea    0x10(%eax,%eax,1),%ebx
80101f72:	89 d8                	mov    %ebx,%eax
80101f74:	e8 53 ff ff ff       	call   80101ecc <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80101f79:	8b 55 0c             	mov    0xc(%ebp),%edx
80101f7c:	c1 e2 18             	shl    $0x18,%edx
80101f7f:	8d 43 01             	lea    0x1(%ebx),%eax
80101f82:	e8 45 ff ff ff       	call   80101ecc <ioapicwrite>
}
80101f87:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101f8a:	c9                   	leave  
80101f8b:	c3                   	ret    

80101f8c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80101f8c:	55                   	push   %ebp
80101f8d:	89 e5                	mov    %esp,%ebp
80101f8f:	53                   	push   %ebx
80101f90:	83 ec 04             	sub    $0x4,%esp
80101f93:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80101f96:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
80101f9c:	75 4c                	jne    80101fea <kfree+0x5e>
80101f9e:	81 fb f0 56 11 80    	cmp    $0x801156f0,%ebx
80101fa4:	72 44                	jb     80101fea <kfree+0x5e>
80101fa6:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80101fac:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80101fb1:	77 37                	ja     80101fea <kfree+0x5e>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80101fb3:	83 ec 04             	sub    $0x4,%esp
80101fb6:	68 00 10 00 00       	push   $0x1000
80101fbb:	6a 01                	push   $0x1
80101fbd:	53                   	push   %ebx
80101fbe:	e8 69 1d 00 00       	call   80103d2c <memset>

  if(kmem.use_lock)
80101fc3:	83 c4 10             	add    $0x10,%esp
80101fc6:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80101fcd:	75 28                	jne    80101ff7 <kfree+0x6b>
    acquire(&kmem.lock);
  r = (struct run*)v;
  r->next = kmem.freelist;
80101fcf:	a1 78 16 11 80       	mov    0x80111678,%eax
80101fd4:	89 03                	mov    %eax,(%ebx)
  kmem.freelist = r;
80101fd6:	89 1d 78 16 11 80    	mov    %ebx,0x80111678
  if(kmem.use_lock)
80101fdc:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
80101fe3:	75 24                	jne    80102009 <kfree+0x7d>
    release(&kmem.lock);
}
80101fe5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101fe8:	c9                   	leave  
80101fe9:	c3                   	ret    
    panic("kfree");
80101fea:	83 ec 0c             	sub    $0xc,%esp
80101fed:	68 c6 6a 10 80       	push   $0x80106ac6
80101ff2:	e8 51 e3 ff ff       	call   80100348 <panic>
    acquire(&kmem.lock);
80101ff7:	83 ec 0c             	sub    $0xc,%esp
80101ffa:	68 40 16 11 80       	push   $0x80111640
80101fff:	e8 7c 1c 00 00       	call   80103c80 <acquire>
80102004:	83 c4 10             	add    $0x10,%esp
80102007:	eb c6                	jmp    80101fcf <kfree+0x43>
    release(&kmem.lock);
80102009:	83 ec 0c             	sub    $0xc,%esp
8010200c:	68 40 16 11 80       	push   $0x80111640
80102011:	e8 cf 1c 00 00       	call   80103ce5 <release>
80102016:	83 c4 10             	add    $0x10,%esp
}
80102019:	eb ca                	jmp    80101fe5 <kfree+0x59>

8010201b <freerange>:
{
8010201b:	55                   	push   %ebp
8010201c:	89 e5                	mov    %esp,%ebp
8010201e:	56                   	push   %esi
8010201f:	53                   	push   %ebx
80102020:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  p = (char*)PGROUNDUP((uint)vstart);
80102023:	8b 45 08             	mov    0x8(%ebp),%eax
80102026:	05 ff 0f 00 00       	add    $0xfff,%eax
8010202b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102030:	eb 0e                	jmp    80102040 <freerange+0x25>
    kfree(p);
80102032:	83 ec 0c             	sub    $0xc,%esp
80102035:	50                   	push   %eax
80102036:	e8 51 ff ff ff       	call   80101f8c <kfree>
8010203b:	83 c4 10             	add    $0x10,%esp
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
8010203e:	89 f0                	mov    %esi,%eax
80102040:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
80102046:	39 de                	cmp    %ebx,%esi
80102048:	76 e8                	jbe    80102032 <freerange+0x17>
}
8010204a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010204d:	5b                   	pop    %ebx
8010204e:	5e                   	pop    %esi
8010204f:	5d                   	pop    %ebp
80102050:	c3                   	ret    

80102051 <kinit1>:
{
80102051:	55                   	push   %ebp
80102052:	89 e5                	mov    %esp,%ebp
80102054:	83 ec 10             	sub    $0x10,%esp
  initlock(&kmem.lock, "kmem");
80102057:	68 cc 6a 10 80       	push   $0x80106acc
8010205c:	68 40 16 11 80       	push   $0x80111640
80102061:	e8 de 1a 00 00       	call   80103b44 <initlock>
  kmem.use_lock = 0;
80102066:	c7 05 74 16 11 80 00 	movl   $0x0,0x80111674
8010206d:	00 00 00 
  freerange(vstart, vend);
80102070:	83 c4 08             	add    $0x8,%esp
80102073:	ff 75 0c             	push   0xc(%ebp)
80102076:	ff 75 08             	push   0x8(%ebp)
80102079:	e8 9d ff ff ff       	call   8010201b <freerange>
}
8010207e:	83 c4 10             	add    $0x10,%esp
80102081:	c9                   	leave  
80102082:	c3                   	ret    

80102083 <kinit2>:
{
80102083:	55                   	push   %ebp
80102084:	89 e5                	mov    %esp,%ebp
80102086:	83 ec 10             	sub    $0x10,%esp
  freerange(vstart, vend);
80102089:	ff 75 0c             	push   0xc(%ebp)
8010208c:	ff 75 08             	push   0x8(%ebp)
8010208f:	e8 87 ff ff ff       	call   8010201b <freerange>
  kmem.use_lock = 1;
80102094:	c7 05 74 16 11 80 01 	movl   $0x1,0x80111674
8010209b:	00 00 00 
}
8010209e:	83 c4 10             	add    $0x10,%esp
801020a1:	c9                   	leave  
801020a2:	c3                   	ret    

801020a3 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
801020a3:	55                   	push   %ebp
801020a4:	89 e5                	mov    %esp,%ebp
801020a6:	53                   	push   %ebx
801020a7:	83 ec 04             	sub    $0x4,%esp
  struct run *r;

  if(kmem.use_lock)
801020aa:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
801020b1:	75 21                	jne    801020d4 <kalloc+0x31>
    acquire(&kmem.lock);
  r = kmem.freelist;
801020b3:	8b 1d 78 16 11 80    	mov    0x80111678,%ebx
  if(r)
801020b9:	85 db                	test   %ebx,%ebx
801020bb:	74 07                	je     801020c4 <kalloc+0x21>
    kmem.freelist = r->next;
801020bd:	8b 03                	mov    (%ebx),%eax
801020bf:	a3 78 16 11 80       	mov    %eax,0x80111678
  if(kmem.use_lock)
801020c4:	83 3d 74 16 11 80 00 	cmpl   $0x0,0x80111674
801020cb:	75 19                	jne    801020e6 <kalloc+0x43>
    release(&kmem.lock);
  return (char*)r;
}
801020cd:	89 d8                	mov    %ebx,%eax
801020cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801020d2:	c9                   	leave  
801020d3:	c3                   	ret    
    acquire(&kmem.lock);
801020d4:	83 ec 0c             	sub    $0xc,%esp
801020d7:	68 40 16 11 80       	push   $0x80111640
801020dc:	e8 9f 1b 00 00       	call   80103c80 <acquire>
801020e1:	83 c4 10             	add    $0x10,%esp
801020e4:	eb cd                	jmp    801020b3 <kalloc+0x10>
    release(&kmem.lock);
801020e6:	83 ec 0c             	sub    $0xc,%esp
801020e9:	68 40 16 11 80       	push   $0x80111640
801020ee:	e8 f2 1b 00 00       	call   80103ce5 <release>
801020f3:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
801020f6:	eb d5                	jmp    801020cd <kalloc+0x2a>

801020f8 <kbdgetc>:
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801020f8:	ba 64 00 00 00       	mov    $0x64,%edx
801020fd:	ec                   	in     (%dx),%al
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
  if((st & KBS_DIB) == 0)
801020fe:	a8 01                	test   $0x1,%al
80102100:	0f 84 b4 00 00 00    	je     801021ba <kbdgetc+0xc2>
80102106:	ba 60 00 00 00       	mov    $0x60,%edx
8010210b:	ec                   	in     (%dx),%al
    return -1;
  data = inb(KBDATAP);
8010210c:	0f b6 c8             	movzbl %al,%ecx

  if(data == 0xE0){
8010210f:	3c e0                	cmp    $0xe0,%al
80102111:	74 61                	je     80102174 <kbdgetc+0x7c>
    shift |= E0ESC;
    return 0;
  } else if(data & 0x80){
80102113:	84 c0                	test   %al,%al
80102115:	78 6a                	js     80102181 <kbdgetc+0x89>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
    shift &= ~(shiftcode[data] | E0ESC);
    return 0;
  } else if(shift & E0ESC){
80102117:	8b 15 7c 16 11 80    	mov    0x8011167c,%edx
8010211d:	f6 c2 40             	test   $0x40,%dl
80102120:	74 0f                	je     80102131 <kbdgetc+0x39>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102122:	83 c8 80             	or     $0xffffff80,%eax
80102125:	0f b6 c8             	movzbl %al,%ecx
    shift &= ~E0ESC;
80102128:	83 e2 bf             	and    $0xffffffbf,%edx
8010212b:	89 15 7c 16 11 80    	mov    %edx,0x8011167c
  }

  shift |= shiftcode[data];
80102131:	0f b6 91 00 6c 10 80 	movzbl -0x7fef9400(%ecx),%edx
80102138:	0b 15 7c 16 11 80    	or     0x8011167c,%edx
8010213e:	89 15 7c 16 11 80    	mov    %edx,0x8011167c
  shift ^= togglecode[data];
80102144:	0f b6 81 00 6b 10 80 	movzbl -0x7fef9500(%ecx),%eax
8010214b:	31 c2                	xor    %eax,%edx
8010214d:	89 15 7c 16 11 80    	mov    %edx,0x8011167c
  c = charcode[shift & (CTL | SHIFT)][data];
80102153:	89 d0                	mov    %edx,%eax
80102155:	83 e0 03             	and    $0x3,%eax
80102158:	8b 04 85 e0 6a 10 80 	mov    -0x7fef9520(,%eax,4),%eax
8010215f:	0f b6 04 08          	movzbl (%eax,%ecx,1),%eax
  if(shift & CAPSLOCK){
80102163:	f6 c2 08             	test   $0x8,%dl
80102166:	74 57                	je     801021bf <kbdgetc+0xc7>
    if('a' <= c && c <= 'z')
80102168:	8d 50 9f             	lea    -0x61(%eax),%edx
8010216b:	83 fa 19             	cmp    $0x19,%edx
8010216e:	77 3e                	ja     801021ae <kbdgetc+0xb6>
      c += 'A' - 'a';
80102170:	83 e8 20             	sub    $0x20,%eax
80102173:	c3                   	ret    
    shift |= E0ESC;
80102174:	83 0d 7c 16 11 80 40 	orl    $0x40,0x8011167c
    return 0;
8010217b:	b8 00 00 00 00       	mov    $0x0,%eax
80102180:	c3                   	ret    
    data = (shift & E0ESC ? data : data & 0x7F);
80102181:	8b 15 7c 16 11 80    	mov    0x8011167c,%edx
80102187:	f6 c2 40             	test   $0x40,%dl
8010218a:	75 05                	jne    80102191 <kbdgetc+0x99>
8010218c:	89 c1                	mov    %eax,%ecx
8010218e:	83 e1 7f             	and    $0x7f,%ecx
    shift &= ~(shiftcode[data] | E0ESC);
80102191:	0f b6 81 00 6c 10 80 	movzbl -0x7fef9400(%ecx),%eax
80102198:	83 c8 40             	or     $0x40,%eax
8010219b:	0f b6 c0             	movzbl %al,%eax
8010219e:	f7 d0                	not    %eax
801021a0:	21 c2                	and    %eax,%edx
801021a2:	89 15 7c 16 11 80    	mov    %edx,0x8011167c
    return 0;
801021a8:	b8 00 00 00 00       	mov    $0x0,%eax
801021ad:	c3                   	ret    
    else if('A' <= c && c <= 'Z')
801021ae:	8d 50 bf             	lea    -0x41(%eax),%edx
801021b1:	83 fa 19             	cmp    $0x19,%edx
801021b4:	77 09                	ja     801021bf <kbdgetc+0xc7>
      c += 'a' - 'A';
801021b6:	83 c0 20             	add    $0x20,%eax
  }
  return c;
801021b9:	c3                   	ret    
    return -1;
801021ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801021bf:	c3                   	ret    

801021c0 <kbdintr>:

void
kbdintr(void)
{
801021c0:	55                   	push   %ebp
801021c1:	89 e5                	mov    %esp,%ebp
801021c3:	83 ec 14             	sub    $0x14,%esp
  consoleintr(kbdgetc);
801021c6:	68 f8 20 10 80       	push   $0x801020f8
801021cb:	e8 63 e5 ff ff       	call   80100733 <consoleintr>
}
801021d0:	83 c4 10             	add    $0x10,%esp
801021d3:	c9                   	leave  
801021d4:	c3                   	ret    

801021d5 <lapicw>:

//PAGEBREAK!
static void
lapicw(int index, int value)
{
  lapic[index] = value;
801021d5:	8b 0d 80 16 11 80    	mov    0x80111680,%ecx
801021db:	8d 04 81             	lea    (%ecx,%eax,4),%eax
801021de:	89 10                	mov    %edx,(%eax)
  lapic[ID];  // wait for write to finish, by reading
801021e0:	a1 80 16 11 80       	mov    0x80111680,%eax
801021e5:	8b 40 20             	mov    0x20(%eax),%eax
}
801021e8:	c3                   	ret    

801021e9 <cmos_read>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801021e9:	ba 70 00 00 00       	mov    $0x70,%edx
801021ee:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801021ef:	ba 71 00 00 00       	mov    $0x71,%edx
801021f4:	ec                   	in     (%dx),%al
cmos_read(uint reg)
{
  outb(CMOS_PORT,  reg);
  microdelay(200);

  return inb(CMOS_RETURN);
801021f5:	0f b6 c0             	movzbl %al,%eax
}
801021f8:	c3                   	ret    

801021f9 <fill_rtcdate>:

static void
fill_rtcdate(struct rtcdate *r)
{
801021f9:	55                   	push   %ebp
801021fa:	89 e5                	mov    %esp,%ebp
801021fc:	53                   	push   %ebx
801021fd:	83 ec 04             	sub    $0x4,%esp
80102200:	89 c3                	mov    %eax,%ebx
  r->second = cmos_read(SECS);
80102202:	b8 00 00 00 00       	mov    $0x0,%eax
80102207:	e8 dd ff ff ff       	call   801021e9 <cmos_read>
8010220c:	89 03                	mov    %eax,(%ebx)
  r->minute = cmos_read(MINS);
8010220e:	b8 02 00 00 00       	mov    $0x2,%eax
80102213:	e8 d1 ff ff ff       	call   801021e9 <cmos_read>
80102218:	89 43 04             	mov    %eax,0x4(%ebx)
  r->hour   = cmos_read(HOURS);
8010221b:	b8 04 00 00 00       	mov    $0x4,%eax
80102220:	e8 c4 ff ff ff       	call   801021e9 <cmos_read>
80102225:	89 43 08             	mov    %eax,0x8(%ebx)
  r->day    = cmos_read(DAY);
80102228:	b8 07 00 00 00       	mov    $0x7,%eax
8010222d:	e8 b7 ff ff ff       	call   801021e9 <cmos_read>
80102232:	89 43 0c             	mov    %eax,0xc(%ebx)
  r->month  = cmos_read(MONTH);
80102235:	b8 08 00 00 00       	mov    $0x8,%eax
8010223a:	e8 aa ff ff ff       	call   801021e9 <cmos_read>
8010223f:	89 43 10             	mov    %eax,0x10(%ebx)
  r->year   = cmos_read(YEAR);
80102242:	b8 09 00 00 00       	mov    $0x9,%eax
80102247:	e8 9d ff ff ff       	call   801021e9 <cmos_read>
8010224c:	89 43 14             	mov    %eax,0x14(%ebx)
}
8010224f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102252:	c9                   	leave  
80102253:	c3                   	ret    

80102254 <lapicinit>:
  if(!lapic)
80102254:	83 3d 80 16 11 80 00 	cmpl   $0x0,0x80111680
8010225b:	0f 84 fe 00 00 00    	je     8010235f <lapicinit+0x10b>
{
80102261:	55                   	push   %ebp
80102262:	89 e5                	mov    %esp,%ebp
80102264:	83 ec 08             	sub    $0x8,%esp
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102267:	ba 3f 01 00 00       	mov    $0x13f,%edx
8010226c:	b8 3c 00 00 00       	mov    $0x3c,%eax
80102271:	e8 5f ff ff ff       	call   801021d5 <lapicw>
  lapicw(TDCR, X1);
80102276:	ba 0b 00 00 00       	mov    $0xb,%edx
8010227b:	b8 f8 00 00 00       	mov    $0xf8,%eax
80102280:	e8 50 ff ff ff       	call   801021d5 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102285:	ba 20 00 02 00       	mov    $0x20020,%edx
8010228a:	b8 c8 00 00 00       	mov    $0xc8,%eax
8010228f:	e8 41 ff ff ff       	call   801021d5 <lapicw>
  lapicw(TICR, 10000000);
80102294:	ba 80 96 98 00       	mov    $0x989680,%edx
80102299:	b8 e0 00 00 00       	mov    $0xe0,%eax
8010229e:	e8 32 ff ff ff       	call   801021d5 <lapicw>
  lapicw(LINT0, MASKED);
801022a3:	ba 00 00 01 00       	mov    $0x10000,%edx
801022a8:	b8 d4 00 00 00       	mov    $0xd4,%eax
801022ad:	e8 23 ff ff ff       	call   801021d5 <lapicw>
  lapicw(LINT1, MASKED);
801022b2:	ba 00 00 01 00       	mov    $0x10000,%edx
801022b7:	b8 d8 00 00 00       	mov    $0xd8,%eax
801022bc:	e8 14 ff ff ff       	call   801021d5 <lapicw>
  if(((lapic[VER]>>16) & 0xFF) >= 4)
801022c1:	a1 80 16 11 80       	mov    0x80111680,%eax
801022c6:	8b 40 30             	mov    0x30(%eax),%eax
801022c9:	c1 e8 10             	shr    $0x10,%eax
801022cc:	a8 fc                	test   $0xfc,%al
801022ce:	75 7b                	jne    8010234b <lapicinit+0xf7>
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
801022d0:	ba 33 00 00 00       	mov    $0x33,%edx
801022d5:	b8 dc 00 00 00       	mov    $0xdc,%eax
801022da:	e8 f6 fe ff ff       	call   801021d5 <lapicw>
  lapicw(ESR, 0);
801022df:	ba 00 00 00 00       	mov    $0x0,%edx
801022e4:	b8 a0 00 00 00       	mov    $0xa0,%eax
801022e9:	e8 e7 fe ff ff       	call   801021d5 <lapicw>
  lapicw(ESR, 0);
801022ee:	ba 00 00 00 00       	mov    $0x0,%edx
801022f3:	b8 a0 00 00 00       	mov    $0xa0,%eax
801022f8:	e8 d8 fe ff ff       	call   801021d5 <lapicw>
  lapicw(EOI, 0);
801022fd:	ba 00 00 00 00       	mov    $0x0,%edx
80102302:	b8 2c 00 00 00       	mov    $0x2c,%eax
80102307:	e8 c9 fe ff ff       	call   801021d5 <lapicw>
  lapicw(ICRHI, 0);
8010230c:	ba 00 00 00 00       	mov    $0x0,%edx
80102311:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102316:	e8 ba fe ff ff       	call   801021d5 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
8010231b:	ba 00 85 08 00       	mov    $0x88500,%edx
80102320:	b8 c0 00 00 00       	mov    $0xc0,%eax
80102325:	e8 ab fe ff ff       	call   801021d5 <lapicw>
  while(lapic[ICRLO] & DELIVS)
8010232a:	a1 80 16 11 80       	mov    0x80111680,%eax
8010232f:	8b 80 00 03 00 00    	mov    0x300(%eax),%eax
80102335:	f6 c4 10             	test   $0x10,%ah
80102338:	75 f0                	jne    8010232a <lapicinit+0xd6>
  lapicw(TPR, 0);
8010233a:	ba 00 00 00 00       	mov    $0x0,%edx
8010233f:	b8 20 00 00 00       	mov    $0x20,%eax
80102344:	e8 8c fe ff ff       	call   801021d5 <lapicw>
}
80102349:	c9                   	leave  
8010234a:	c3                   	ret    
    lapicw(PCINT, MASKED);
8010234b:	ba 00 00 01 00       	mov    $0x10000,%edx
80102350:	b8 d0 00 00 00       	mov    $0xd0,%eax
80102355:	e8 7b fe ff ff       	call   801021d5 <lapicw>
8010235a:	e9 71 ff ff ff       	jmp    801022d0 <lapicinit+0x7c>
8010235f:	c3                   	ret    

80102360 <lapicid>:
  if (!lapic)
80102360:	a1 80 16 11 80       	mov    0x80111680,%eax
80102365:	85 c0                	test   %eax,%eax
80102367:	74 07                	je     80102370 <lapicid+0x10>
  return lapic[ID] >> 24;
80102369:	8b 40 20             	mov    0x20(%eax),%eax
8010236c:	c1 e8 18             	shr    $0x18,%eax
8010236f:	c3                   	ret    
    return 0;
80102370:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102375:	c3                   	ret    

80102376 <lapiceoi>:
  if(lapic)
80102376:	83 3d 80 16 11 80 00 	cmpl   $0x0,0x80111680
8010237d:	74 17                	je     80102396 <lapiceoi+0x20>
{
8010237f:	55                   	push   %ebp
80102380:	89 e5                	mov    %esp,%ebp
80102382:	83 ec 08             	sub    $0x8,%esp
    lapicw(EOI, 0);
80102385:	ba 00 00 00 00       	mov    $0x0,%edx
8010238a:	b8 2c 00 00 00       	mov    $0x2c,%eax
8010238f:	e8 41 fe ff ff       	call   801021d5 <lapicw>
}
80102394:	c9                   	leave  
80102395:	c3                   	ret    
80102396:	c3                   	ret    

80102397 <microdelay>:
}
80102397:	c3                   	ret    

80102398 <lapicstartap>:
{
80102398:	55                   	push   %ebp
80102399:	89 e5                	mov    %esp,%ebp
8010239b:	57                   	push   %edi
8010239c:	56                   	push   %esi
8010239d:	53                   	push   %ebx
8010239e:	83 ec 0c             	sub    $0xc,%esp
801023a1:	8b 75 08             	mov    0x8(%ebp),%esi
801023a4:	8b 7d 0c             	mov    0xc(%ebp),%edi
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801023a7:	b8 0f 00 00 00       	mov    $0xf,%eax
801023ac:	ba 70 00 00 00       	mov    $0x70,%edx
801023b1:	ee                   	out    %al,(%dx)
801023b2:	b8 0a 00 00 00       	mov    $0xa,%eax
801023b7:	ba 71 00 00 00       	mov    $0x71,%edx
801023bc:	ee                   	out    %al,(%dx)
  wrv[0] = 0;
801023bd:	66 c7 05 67 04 00 80 	movw   $0x0,0x80000467
801023c4:	00 00 
  wrv[1] = addr >> 4;
801023c6:	89 f8                	mov    %edi,%eax
801023c8:	c1 e8 04             	shr    $0x4,%eax
801023cb:	66 a3 69 04 00 80    	mov    %ax,0x80000469
  lapicw(ICRHI, apicid<<24);
801023d1:	c1 e6 18             	shl    $0x18,%esi
801023d4:	89 f2                	mov    %esi,%edx
801023d6:	b8 c4 00 00 00       	mov    $0xc4,%eax
801023db:	e8 f5 fd ff ff       	call   801021d5 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801023e0:	ba 00 c5 00 00       	mov    $0xc500,%edx
801023e5:	b8 c0 00 00 00       	mov    $0xc0,%eax
801023ea:	e8 e6 fd ff ff       	call   801021d5 <lapicw>
  lapicw(ICRLO, INIT | LEVEL);
801023ef:	ba 00 85 00 00       	mov    $0x8500,%edx
801023f4:	b8 c0 00 00 00       	mov    $0xc0,%eax
801023f9:	e8 d7 fd ff ff       	call   801021d5 <lapicw>
  for(i = 0; i < 2; i++){
801023fe:	bb 00 00 00 00       	mov    $0x0,%ebx
80102403:	eb 21                	jmp    80102426 <lapicstartap+0x8e>
    lapicw(ICRHI, apicid<<24);
80102405:	89 f2                	mov    %esi,%edx
80102407:	b8 c4 00 00 00       	mov    $0xc4,%eax
8010240c:	e8 c4 fd ff ff       	call   801021d5 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80102411:	89 fa                	mov    %edi,%edx
80102413:	c1 ea 0c             	shr    $0xc,%edx
80102416:	80 ce 06             	or     $0x6,%dh
80102419:	b8 c0 00 00 00       	mov    $0xc0,%eax
8010241e:	e8 b2 fd ff ff       	call   801021d5 <lapicw>
  for(i = 0; i < 2; i++){
80102423:	83 c3 01             	add    $0x1,%ebx
80102426:	83 fb 01             	cmp    $0x1,%ebx
80102429:	7e da                	jle    80102405 <lapicstartap+0x6d>
}
8010242b:	83 c4 0c             	add    $0xc,%esp
8010242e:	5b                   	pop    %ebx
8010242f:	5e                   	pop    %esi
80102430:	5f                   	pop    %edi
80102431:	5d                   	pop    %ebp
80102432:	c3                   	ret    

80102433 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void
cmostime(struct rtcdate *r)
{
80102433:	55                   	push   %ebp
80102434:	89 e5                	mov    %esp,%ebp
80102436:	57                   	push   %edi
80102437:	56                   	push   %esi
80102438:	53                   	push   %ebx
80102439:	83 ec 3c             	sub    $0x3c,%esp
8010243c:	8b 75 08             	mov    0x8(%ebp),%esi
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
8010243f:	b8 0b 00 00 00       	mov    $0xb,%eax
80102444:	e8 a0 fd ff ff       	call   801021e9 <cmos_read>

  bcd = (sb & (1 << 2)) == 0;
80102449:	83 e0 04             	and    $0x4,%eax
8010244c:	89 c7                	mov    %eax,%edi

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
8010244e:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102451:	e8 a3 fd ff ff       	call   801021f9 <fill_rtcdate>
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
80102456:	b8 0a 00 00 00       	mov    $0xa,%eax
8010245b:	e8 89 fd ff ff       	call   801021e9 <cmos_read>
80102460:	a8 80                	test   $0x80,%al
80102462:	75 ea                	jne    8010244e <cmostime+0x1b>
        continue;
    fill_rtcdate(&t2);
80102464:	8d 5d b8             	lea    -0x48(%ebp),%ebx
80102467:	89 d8                	mov    %ebx,%eax
80102469:	e8 8b fd ff ff       	call   801021f9 <fill_rtcdate>
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
8010246e:	83 ec 04             	sub    $0x4,%esp
80102471:	6a 18                	push   $0x18
80102473:	53                   	push   %ebx
80102474:	8d 45 d0             	lea    -0x30(%ebp),%eax
80102477:	50                   	push   %eax
80102478:	e8 f2 18 00 00       	call   80103d6f <memcmp>
8010247d:	83 c4 10             	add    $0x10,%esp
80102480:	85 c0                	test   %eax,%eax
80102482:	75 ca                	jne    8010244e <cmostime+0x1b>
      break;
  }

  // convert
  if(bcd) {
80102484:	85 ff                	test   %edi,%edi
80102486:	75 78                	jne    80102500 <cmostime+0xcd>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80102488:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010248b:	89 c2                	mov    %eax,%edx
8010248d:	c1 ea 04             	shr    $0x4,%edx
80102490:	8d 14 92             	lea    (%edx,%edx,4),%edx
80102493:	83 e0 0f             	and    $0xf,%eax
80102496:	8d 04 50             	lea    (%eax,%edx,2),%eax
80102499:	89 45 d0             	mov    %eax,-0x30(%ebp)
    CONV(minute);
8010249c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010249f:	89 c2                	mov    %eax,%edx
801024a1:	c1 ea 04             	shr    $0x4,%edx
801024a4:	8d 14 92             	lea    (%edx,%edx,4),%edx
801024a7:	83 e0 0f             	and    $0xf,%eax
801024aa:	8d 04 50             	lea    (%eax,%edx,2),%eax
801024ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    CONV(hour  );
801024b0:	8b 45 d8             	mov    -0x28(%ebp),%eax
801024b3:	89 c2                	mov    %eax,%edx
801024b5:	c1 ea 04             	shr    $0x4,%edx
801024b8:	8d 14 92             	lea    (%edx,%edx,4),%edx
801024bb:	83 e0 0f             	and    $0xf,%eax
801024be:	8d 04 50             	lea    (%eax,%edx,2),%eax
801024c1:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(day   );
801024c4:	8b 45 dc             	mov    -0x24(%ebp),%eax
801024c7:	89 c2                	mov    %eax,%edx
801024c9:	c1 ea 04             	shr    $0x4,%edx
801024cc:	8d 14 92             	lea    (%edx,%edx,4),%edx
801024cf:	83 e0 0f             	and    $0xf,%eax
801024d2:	8d 04 50             	lea    (%eax,%edx,2),%eax
801024d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(month );
801024d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801024db:	89 c2                	mov    %eax,%edx
801024dd:	c1 ea 04             	shr    $0x4,%edx
801024e0:	8d 14 92             	lea    (%edx,%edx,4),%edx
801024e3:	83 e0 0f             	and    $0xf,%eax
801024e6:	8d 04 50             	lea    (%eax,%edx,2),%eax
801024e9:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(year  );
801024ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801024ef:	89 c2                	mov    %eax,%edx
801024f1:	c1 ea 04             	shr    $0x4,%edx
801024f4:	8d 14 92             	lea    (%edx,%edx,4),%edx
801024f7:	83 e0 0f             	and    $0xf,%eax
801024fa:	8d 04 50             	lea    (%eax,%edx,2),%eax
801024fd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
#undef     CONV
  }

  *r = t1;
80102500:	8b 45 d0             	mov    -0x30(%ebp),%eax
80102503:	89 06                	mov    %eax,(%esi)
80102505:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80102508:	89 46 04             	mov    %eax,0x4(%esi)
8010250b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010250e:	89 46 08             	mov    %eax,0x8(%esi)
80102511:	8b 45 dc             	mov    -0x24(%ebp),%eax
80102514:	89 46 0c             	mov    %eax,0xc(%esi)
80102517:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010251a:	89 46 10             	mov    %eax,0x10(%esi)
8010251d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102520:	89 46 14             	mov    %eax,0x14(%esi)
  r->year += 2000;
80102523:	81 46 14 d0 07 00 00 	addl   $0x7d0,0x14(%esi)
}
8010252a:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010252d:	5b                   	pop    %ebx
8010252e:	5e                   	pop    %esi
8010252f:	5f                   	pop    %edi
80102530:	5d                   	pop    %ebp
80102531:	c3                   	ret    

80102532 <read_head>:
}

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80102532:	55                   	push   %ebp
80102533:	89 e5                	mov    %esp,%ebp
80102535:	53                   	push   %ebx
80102536:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
80102539:	ff 35 d4 16 11 80    	push   0x801116d4
8010253f:	ff 35 e4 16 11 80    	push   0x801116e4
80102545:	e8 22 dc ff ff       	call   8010016c <bread>
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
8010254a:	8b 58 5c             	mov    0x5c(%eax),%ebx
8010254d:	89 1d e8 16 11 80    	mov    %ebx,0x801116e8
  for (i = 0; i < log.lh.n; i++) {
80102553:	83 c4 10             	add    $0x10,%esp
80102556:	ba 00 00 00 00       	mov    $0x0,%edx
8010255b:	eb 0e                	jmp    8010256b <read_head+0x39>
    log.lh.block[i] = lh->block[i];
8010255d:	8b 4c 90 60          	mov    0x60(%eax,%edx,4),%ecx
80102561:	89 0c 95 ec 16 11 80 	mov    %ecx,-0x7feee914(,%edx,4)
  for (i = 0; i < log.lh.n; i++) {
80102568:	83 c2 01             	add    $0x1,%edx
8010256b:	39 d3                	cmp    %edx,%ebx
8010256d:	7f ee                	jg     8010255d <read_head+0x2b>
  }
  brelse(buf);
8010256f:	83 ec 0c             	sub    $0xc,%esp
80102572:	50                   	push   %eax
80102573:	e8 5d dc ff ff       	call   801001d5 <brelse>
}
80102578:	83 c4 10             	add    $0x10,%esp
8010257b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010257e:	c9                   	leave  
8010257f:	c3                   	ret    

80102580 <install_trans>:
{
80102580:	55                   	push   %ebp
80102581:	89 e5                	mov    %esp,%ebp
80102583:	57                   	push   %edi
80102584:	56                   	push   %esi
80102585:	53                   	push   %ebx
80102586:	83 ec 0c             	sub    $0xc,%esp
  for (tail = 0; tail < log.lh.n; tail++) {
80102589:	be 00 00 00 00       	mov    $0x0,%esi
8010258e:	eb 66                	jmp    801025f6 <install_trans+0x76>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80102590:	89 f0                	mov    %esi,%eax
80102592:	03 05 d4 16 11 80    	add    0x801116d4,%eax
80102598:	83 c0 01             	add    $0x1,%eax
8010259b:	83 ec 08             	sub    $0x8,%esp
8010259e:	50                   	push   %eax
8010259f:	ff 35 e4 16 11 80    	push   0x801116e4
801025a5:	e8 c2 db ff ff       	call   8010016c <bread>
801025aa:	89 c7                	mov    %eax,%edi
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
801025ac:	83 c4 08             	add    $0x8,%esp
801025af:	ff 34 b5 ec 16 11 80 	push   -0x7feee914(,%esi,4)
801025b6:	ff 35 e4 16 11 80    	push   0x801116e4
801025bc:	e8 ab db ff ff       	call   8010016c <bread>
801025c1:	89 c3                	mov    %eax,%ebx
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801025c3:	8d 57 5c             	lea    0x5c(%edi),%edx
801025c6:	8d 40 5c             	lea    0x5c(%eax),%eax
801025c9:	83 c4 0c             	add    $0xc,%esp
801025cc:	68 00 02 00 00       	push   $0x200
801025d1:	52                   	push   %edx
801025d2:	50                   	push   %eax
801025d3:	e8 cc 17 00 00       	call   80103da4 <memmove>
    bwrite(dbuf);  // write dst to disk
801025d8:	89 1c 24             	mov    %ebx,(%esp)
801025db:	e8 ba db ff ff       	call   8010019a <bwrite>
    brelse(lbuf);
801025e0:	89 3c 24             	mov    %edi,(%esp)
801025e3:	e8 ed db ff ff       	call   801001d5 <brelse>
    brelse(dbuf);
801025e8:	89 1c 24             	mov    %ebx,(%esp)
801025eb:	e8 e5 db ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801025f0:	83 c6 01             	add    $0x1,%esi
801025f3:	83 c4 10             	add    $0x10,%esp
801025f6:	39 35 e8 16 11 80    	cmp    %esi,0x801116e8
801025fc:	7f 92                	jg     80102590 <install_trans+0x10>
}
801025fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102601:	5b                   	pop    %ebx
80102602:	5e                   	pop    %esi
80102603:	5f                   	pop    %edi
80102604:	5d                   	pop    %ebp
80102605:	c3                   	ret    

80102606 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80102606:	55                   	push   %ebp
80102607:	89 e5                	mov    %esp,%ebp
80102609:	53                   	push   %ebx
8010260a:	83 ec 0c             	sub    $0xc,%esp
  struct buf *buf = bread(log.dev, log.start);
8010260d:	ff 35 d4 16 11 80    	push   0x801116d4
80102613:	ff 35 e4 16 11 80    	push   0x801116e4
80102619:	e8 4e db ff ff       	call   8010016c <bread>
8010261e:	89 c3                	mov    %eax,%ebx
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
80102620:	8b 0d e8 16 11 80    	mov    0x801116e8,%ecx
80102626:	89 48 5c             	mov    %ecx,0x5c(%eax)
  for (i = 0; i < log.lh.n; i++) {
80102629:	83 c4 10             	add    $0x10,%esp
8010262c:	b8 00 00 00 00       	mov    $0x0,%eax
80102631:	eb 0e                	jmp    80102641 <write_head+0x3b>
    hb->block[i] = log.lh.block[i];
80102633:	8b 14 85 ec 16 11 80 	mov    -0x7feee914(,%eax,4),%edx
8010263a:	89 54 83 60          	mov    %edx,0x60(%ebx,%eax,4)
  for (i = 0; i < log.lh.n; i++) {
8010263e:	83 c0 01             	add    $0x1,%eax
80102641:	39 c1                	cmp    %eax,%ecx
80102643:	7f ee                	jg     80102633 <write_head+0x2d>
  }
  bwrite(buf);
80102645:	83 ec 0c             	sub    $0xc,%esp
80102648:	53                   	push   %ebx
80102649:	e8 4c db ff ff       	call   8010019a <bwrite>
  brelse(buf);
8010264e:	89 1c 24             	mov    %ebx,(%esp)
80102651:	e8 7f db ff ff       	call   801001d5 <brelse>
}
80102656:	83 c4 10             	add    $0x10,%esp
80102659:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010265c:	c9                   	leave  
8010265d:	c3                   	ret    

8010265e <recover_from_log>:

static void
recover_from_log(void)
{
8010265e:	55                   	push   %ebp
8010265f:	89 e5                	mov    %esp,%ebp
80102661:	83 ec 08             	sub    $0x8,%esp
  read_head();
80102664:	e8 c9 fe ff ff       	call   80102532 <read_head>
  install_trans(); // if committed, copy from log to disk
80102669:	e8 12 ff ff ff       	call   80102580 <install_trans>
  log.lh.n = 0;
8010266e:	c7 05 e8 16 11 80 00 	movl   $0x0,0x801116e8
80102675:	00 00 00 
  write_head(); // clear the log
80102678:	e8 89 ff ff ff       	call   80102606 <write_head>
}
8010267d:	c9                   	leave  
8010267e:	c3                   	ret    

8010267f <write_log>:
}

// Copy modified blocks from cache to log.
static void
write_log(void)
{
8010267f:	55                   	push   %ebp
80102680:	89 e5                	mov    %esp,%ebp
80102682:	57                   	push   %edi
80102683:	56                   	push   %esi
80102684:	53                   	push   %ebx
80102685:	83 ec 0c             	sub    $0xc,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80102688:	be 00 00 00 00       	mov    $0x0,%esi
8010268d:	eb 66                	jmp    801026f5 <write_log+0x76>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
8010268f:	89 f0                	mov    %esi,%eax
80102691:	03 05 d4 16 11 80    	add    0x801116d4,%eax
80102697:	83 c0 01             	add    $0x1,%eax
8010269a:	83 ec 08             	sub    $0x8,%esp
8010269d:	50                   	push   %eax
8010269e:	ff 35 e4 16 11 80    	push   0x801116e4
801026a4:	e8 c3 da ff ff       	call   8010016c <bread>
801026a9:	89 c3                	mov    %eax,%ebx
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801026ab:	83 c4 08             	add    $0x8,%esp
801026ae:	ff 34 b5 ec 16 11 80 	push   -0x7feee914(,%esi,4)
801026b5:	ff 35 e4 16 11 80    	push   0x801116e4
801026bb:	e8 ac da ff ff       	call   8010016c <bread>
801026c0:	89 c7                	mov    %eax,%edi
    memmove(to->data, from->data, BSIZE);
801026c2:	8d 50 5c             	lea    0x5c(%eax),%edx
801026c5:	8d 43 5c             	lea    0x5c(%ebx),%eax
801026c8:	83 c4 0c             	add    $0xc,%esp
801026cb:	68 00 02 00 00       	push   $0x200
801026d0:	52                   	push   %edx
801026d1:	50                   	push   %eax
801026d2:	e8 cd 16 00 00       	call   80103da4 <memmove>
    bwrite(to);  // write the log
801026d7:	89 1c 24             	mov    %ebx,(%esp)
801026da:	e8 bb da ff ff       	call   8010019a <bwrite>
    brelse(from);
801026df:	89 3c 24             	mov    %edi,(%esp)
801026e2:	e8 ee da ff ff       	call   801001d5 <brelse>
    brelse(to);
801026e7:	89 1c 24             	mov    %ebx,(%esp)
801026ea:	e8 e6 da ff ff       	call   801001d5 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
801026ef:	83 c6 01             	add    $0x1,%esi
801026f2:	83 c4 10             	add    $0x10,%esp
801026f5:	39 35 e8 16 11 80    	cmp    %esi,0x801116e8
801026fb:	7f 92                	jg     8010268f <write_log+0x10>
  }
}
801026fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102700:	5b                   	pop    %ebx
80102701:	5e                   	pop    %esi
80102702:	5f                   	pop    %edi
80102703:	5d                   	pop    %ebp
80102704:	c3                   	ret    

80102705 <commit>:

static void
commit()
{
  if (log.lh.n > 0) {
80102705:	83 3d e8 16 11 80 00 	cmpl   $0x0,0x801116e8
8010270c:	7f 01                	jg     8010270f <commit+0xa>
8010270e:	c3                   	ret    
{
8010270f:	55                   	push   %ebp
80102710:	89 e5                	mov    %esp,%ebp
80102712:	83 ec 08             	sub    $0x8,%esp
    write_log();     // Write modified blocks from cache to log
80102715:	e8 65 ff ff ff       	call   8010267f <write_log>
    write_head();    // Write header to disk -- the real commit
8010271a:	e8 e7 fe ff ff       	call   80102606 <write_head>
    install_trans(); // Now install writes to home locations
8010271f:	e8 5c fe ff ff       	call   80102580 <install_trans>
    log.lh.n = 0;
80102724:	c7 05 e8 16 11 80 00 	movl   $0x0,0x801116e8
8010272b:	00 00 00 
    write_head();    // Erase the transaction from the log
8010272e:	e8 d3 fe ff ff       	call   80102606 <write_head>
  }
}
80102733:	c9                   	leave  
80102734:	c3                   	ret    

80102735 <initlog>:
{
80102735:	55                   	push   %ebp
80102736:	89 e5                	mov    %esp,%ebp
80102738:	53                   	push   %ebx
80102739:	83 ec 2c             	sub    $0x2c,%esp
8010273c:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&log.lock, "log");
8010273f:	68 00 6d 10 80       	push   $0x80106d00
80102744:	68 a0 16 11 80       	push   $0x801116a0
80102749:	e8 f6 13 00 00       	call   80103b44 <initlock>
  readsb(dev, &sb);
8010274e:	83 c4 08             	add    $0x8,%esp
80102751:	8d 45 dc             	lea    -0x24(%ebp),%eax
80102754:	50                   	push   %eax
80102755:	53                   	push   %ebx
80102756:	e8 4b eb ff ff       	call   801012a6 <readsb>
  log.start = sb.logstart;
8010275b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010275e:	a3 d4 16 11 80       	mov    %eax,0x801116d4
  log.size = sb.nlog;
80102763:	8b 45 e8             	mov    -0x18(%ebp),%eax
80102766:	a3 d8 16 11 80       	mov    %eax,0x801116d8
  log.dev = dev;
8010276b:	89 1d e4 16 11 80    	mov    %ebx,0x801116e4
  recover_from_log();
80102771:	e8 e8 fe ff ff       	call   8010265e <recover_from_log>
}
80102776:	83 c4 10             	add    $0x10,%esp
80102779:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010277c:	c9                   	leave  
8010277d:	c3                   	ret    

8010277e <begin_op>:
{
8010277e:	55                   	push   %ebp
8010277f:	89 e5                	mov    %esp,%ebp
80102781:	83 ec 14             	sub    $0x14,%esp
  acquire(&log.lock);
80102784:	68 a0 16 11 80       	push   $0x801116a0
80102789:	e8 f2 14 00 00       	call   80103c80 <acquire>
8010278e:	83 c4 10             	add    $0x10,%esp
80102791:	eb 15                	jmp    801027a8 <begin_op+0x2a>
      sleep(&log, &log.lock);
80102793:	83 ec 08             	sub    $0x8,%esp
80102796:	68 a0 16 11 80       	push   $0x801116a0
8010279b:	68 a0 16 11 80       	push   $0x801116a0
801027a0:	e8 d8 0f 00 00       	call   8010377d <sleep>
801027a5:	83 c4 10             	add    $0x10,%esp
    if(log.committing){
801027a8:	83 3d e0 16 11 80 00 	cmpl   $0x0,0x801116e0
801027af:	75 e2                	jne    80102793 <begin_op+0x15>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
801027b1:	a1 dc 16 11 80       	mov    0x801116dc,%eax
801027b6:	83 c0 01             	add    $0x1,%eax
801027b9:	8d 0c 80             	lea    (%eax,%eax,4),%ecx
801027bc:	8d 14 09             	lea    (%ecx,%ecx,1),%edx
801027bf:	03 15 e8 16 11 80    	add    0x801116e8,%edx
801027c5:	83 fa 1e             	cmp    $0x1e,%edx
801027c8:	7e 17                	jle    801027e1 <begin_op+0x63>
      sleep(&log, &log.lock);
801027ca:	83 ec 08             	sub    $0x8,%esp
801027cd:	68 a0 16 11 80       	push   $0x801116a0
801027d2:	68 a0 16 11 80       	push   $0x801116a0
801027d7:	e8 a1 0f 00 00       	call   8010377d <sleep>
801027dc:	83 c4 10             	add    $0x10,%esp
801027df:	eb c7                	jmp    801027a8 <begin_op+0x2a>
      log.outstanding += 1;
801027e1:	a3 dc 16 11 80       	mov    %eax,0x801116dc
      release(&log.lock);
801027e6:	83 ec 0c             	sub    $0xc,%esp
801027e9:	68 a0 16 11 80       	push   $0x801116a0
801027ee:	e8 f2 14 00 00       	call   80103ce5 <release>
}
801027f3:	83 c4 10             	add    $0x10,%esp
801027f6:	c9                   	leave  
801027f7:	c3                   	ret    

801027f8 <end_op>:
{
801027f8:	55                   	push   %ebp
801027f9:	89 e5                	mov    %esp,%ebp
801027fb:	53                   	push   %ebx
801027fc:	83 ec 10             	sub    $0x10,%esp
  acquire(&log.lock);
801027ff:	68 a0 16 11 80       	push   $0x801116a0
80102804:	e8 77 14 00 00       	call   80103c80 <acquire>
  log.outstanding -= 1;
80102809:	a1 dc 16 11 80       	mov    0x801116dc,%eax
8010280e:	83 e8 01             	sub    $0x1,%eax
80102811:	a3 dc 16 11 80       	mov    %eax,0x801116dc
  if(log.committing)
80102816:	8b 1d e0 16 11 80    	mov    0x801116e0,%ebx
8010281c:	83 c4 10             	add    $0x10,%esp
8010281f:	85 db                	test   %ebx,%ebx
80102821:	75 2c                	jne    8010284f <end_op+0x57>
  if(log.outstanding == 0){
80102823:	85 c0                	test   %eax,%eax
80102825:	75 35                	jne    8010285c <end_op+0x64>
    log.committing = 1;
80102827:	c7 05 e0 16 11 80 01 	movl   $0x1,0x801116e0
8010282e:	00 00 00 
    do_commit = 1;
80102831:	bb 01 00 00 00       	mov    $0x1,%ebx
  release(&log.lock);
80102836:	83 ec 0c             	sub    $0xc,%esp
80102839:	68 a0 16 11 80       	push   $0x801116a0
8010283e:	e8 a2 14 00 00       	call   80103ce5 <release>
  if(do_commit){
80102843:	83 c4 10             	add    $0x10,%esp
80102846:	85 db                	test   %ebx,%ebx
80102848:	75 24                	jne    8010286e <end_op+0x76>
}
8010284a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010284d:	c9                   	leave  
8010284e:	c3                   	ret    
    panic("log.committing");
8010284f:	83 ec 0c             	sub    $0xc,%esp
80102852:	68 04 6d 10 80       	push   $0x80106d04
80102857:	e8 ec da ff ff       	call   80100348 <panic>
    wakeup(&log);
8010285c:	83 ec 0c             	sub    $0xc,%esp
8010285f:	68 a0 16 11 80       	push   $0x801116a0
80102864:	e8 7c 10 00 00       	call   801038e5 <wakeup>
80102869:	83 c4 10             	add    $0x10,%esp
8010286c:	eb c8                	jmp    80102836 <end_op+0x3e>
    commit();
8010286e:	e8 92 fe ff ff       	call   80102705 <commit>
    acquire(&log.lock);
80102873:	83 ec 0c             	sub    $0xc,%esp
80102876:	68 a0 16 11 80       	push   $0x801116a0
8010287b:	e8 00 14 00 00       	call   80103c80 <acquire>
    log.committing = 0;
80102880:	c7 05 e0 16 11 80 00 	movl   $0x0,0x801116e0
80102887:	00 00 00 
    wakeup(&log);
8010288a:	c7 04 24 a0 16 11 80 	movl   $0x801116a0,(%esp)
80102891:	e8 4f 10 00 00       	call   801038e5 <wakeup>
    release(&log.lock);
80102896:	c7 04 24 a0 16 11 80 	movl   $0x801116a0,(%esp)
8010289d:	e8 43 14 00 00       	call   80103ce5 <release>
801028a2:	83 c4 10             	add    $0x10,%esp
}
801028a5:	eb a3                	jmp    8010284a <end_op+0x52>

801028a7 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
801028a7:	55                   	push   %ebp
801028a8:	89 e5                	mov    %esp,%ebp
801028aa:	53                   	push   %ebx
801028ab:	83 ec 04             	sub    $0x4,%esp
801028ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
801028b1:	8b 15 e8 16 11 80    	mov    0x801116e8,%edx
801028b7:	83 fa 1d             	cmp    $0x1d,%edx
801028ba:	7f 2c                	jg     801028e8 <log_write+0x41>
801028bc:	a1 d8 16 11 80       	mov    0x801116d8,%eax
801028c1:	83 e8 01             	sub    $0x1,%eax
801028c4:	39 c2                	cmp    %eax,%edx
801028c6:	7d 20                	jge    801028e8 <log_write+0x41>
    panic("too big a transaction");
  if (log.outstanding < 1)
801028c8:	83 3d dc 16 11 80 00 	cmpl   $0x0,0x801116dc
801028cf:	7e 24                	jle    801028f5 <log_write+0x4e>
    panic("log_write outside of trans");

  acquire(&log.lock);
801028d1:	83 ec 0c             	sub    $0xc,%esp
801028d4:	68 a0 16 11 80       	push   $0x801116a0
801028d9:	e8 a2 13 00 00       	call   80103c80 <acquire>
  for (i = 0; i < log.lh.n; i++) {
801028de:	83 c4 10             	add    $0x10,%esp
801028e1:	b8 00 00 00 00       	mov    $0x0,%eax
801028e6:	eb 1d                	jmp    80102905 <log_write+0x5e>
    panic("too big a transaction");
801028e8:	83 ec 0c             	sub    $0xc,%esp
801028eb:	68 13 6d 10 80       	push   $0x80106d13
801028f0:	e8 53 da ff ff       	call   80100348 <panic>
    panic("log_write outside of trans");
801028f5:	83 ec 0c             	sub    $0xc,%esp
801028f8:	68 29 6d 10 80       	push   $0x80106d29
801028fd:	e8 46 da ff ff       	call   80100348 <panic>
  for (i = 0; i < log.lh.n; i++) {
80102902:	83 c0 01             	add    $0x1,%eax
80102905:	8b 15 e8 16 11 80    	mov    0x801116e8,%edx
8010290b:	39 c2                	cmp    %eax,%edx
8010290d:	7e 0c                	jle    8010291b <log_write+0x74>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
8010290f:	8b 4b 08             	mov    0x8(%ebx),%ecx
80102912:	39 0c 85 ec 16 11 80 	cmp    %ecx,-0x7feee914(,%eax,4)
80102919:	75 e7                	jne    80102902 <log_write+0x5b>
      break;
  }
  log.lh.block[i] = b->blockno;
8010291b:	8b 4b 08             	mov    0x8(%ebx),%ecx
8010291e:	89 0c 85 ec 16 11 80 	mov    %ecx,-0x7feee914(,%eax,4)
  if (i == log.lh.n)
80102925:	39 c2                	cmp    %eax,%edx
80102927:	74 18                	je     80102941 <log_write+0x9a>
    log.lh.n++;
  b->flags |= B_DIRTY; // prevent eviction
80102929:	83 0b 04             	orl    $0x4,(%ebx)
  release(&log.lock);
8010292c:	83 ec 0c             	sub    $0xc,%esp
8010292f:	68 a0 16 11 80       	push   $0x801116a0
80102934:	e8 ac 13 00 00       	call   80103ce5 <release>
}
80102939:	83 c4 10             	add    $0x10,%esp
8010293c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010293f:	c9                   	leave  
80102940:	c3                   	ret    
    log.lh.n++;
80102941:	83 c2 01             	add    $0x1,%edx
80102944:	89 15 e8 16 11 80    	mov    %edx,0x801116e8
8010294a:	eb dd                	jmp    80102929 <log_write+0x82>

8010294c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010294c:	55                   	push   %ebp
8010294d:	89 e5                	mov    %esp,%ebp
8010294f:	53                   	push   %ebx
80102950:	83 ec 08             	sub    $0x8,%esp

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80102953:	68 8a 00 00 00       	push   $0x8a
80102958:	68 8c a4 10 80       	push   $0x8010a48c
8010295d:	68 00 70 00 80       	push   $0x80007000
80102962:	e8 3d 14 00 00       	call   80103da4 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80102967:	83 c4 10             	add    $0x10,%esp
8010296a:	bb a0 17 11 80       	mov    $0x801117a0,%ebx
8010296f:	eb 06                	jmp    80102977 <startothers+0x2b>
80102971:	81 c3 b0 00 00 00    	add    $0xb0,%ebx
80102977:	69 05 84 17 11 80 b0 	imul   $0xb0,0x80111784,%eax
8010297e:	00 00 00 
80102981:	05 a0 17 11 80       	add    $0x801117a0,%eax
80102986:	39 d8                	cmp    %ebx,%eax
80102988:	76 4c                	jbe    801029d6 <startothers+0x8a>
    if(c == mycpu())  // We've started already.
8010298a:	e8 15 08 00 00       	call   801031a4 <mycpu>
8010298f:	39 c3                	cmp    %eax,%ebx
80102991:	74 de                	je     80102971 <startothers+0x25>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80102993:	e8 0b f7 ff ff       	call   801020a3 <kalloc>
    *(void**)(code-4) = stack + KSTACKSIZE;
80102998:	05 00 10 00 00       	add    $0x1000,%eax
8010299d:	a3 fc 6f 00 80       	mov    %eax,0x80006ffc
    *(void(**)(void))(code-8) = mpenter;
801029a2:	c7 05 f8 6f 00 80 1a 	movl   $0x80102a1a,0x80006ff8
801029a9:	2a 10 80 
    *(int**)(code-12) = (void *) V2P(entrypgdir);
801029ac:	c7 05 f4 6f 00 80 00 	movl   $0x109000,0x80006ff4
801029b3:	90 10 00 

    lapicstartap(c->apicid, V2P(code));
801029b6:	83 ec 08             	sub    $0x8,%esp
801029b9:	68 00 70 00 00       	push   $0x7000
801029be:	0f b6 03             	movzbl (%ebx),%eax
801029c1:	50                   	push   %eax
801029c2:	e8 d1 f9 ff ff       	call   80102398 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801029c7:	83 c4 10             	add    $0x10,%esp
801029ca:	8b 83 a0 00 00 00    	mov    0xa0(%ebx),%eax
801029d0:	85 c0                	test   %eax,%eax
801029d2:	74 f6                	je     801029ca <startothers+0x7e>
801029d4:	eb 9b                	jmp    80102971 <startothers+0x25>
      ;
  }
}
801029d6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801029d9:	c9                   	leave  
801029da:	c3                   	ret    

801029db <mpmain>:
{
801029db:	55                   	push   %ebp
801029dc:	89 e5                	mov    %esp,%ebp
801029de:	53                   	push   %ebx
801029df:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
801029e2:	e8 19 08 00 00       	call   80103200 <cpuid>
801029e7:	89 c3                	mov    %eax,%ebx
801029e9:	e8 12 08 00 00       	call   80103200 <cpuid>
801029ee:	83 ec 04             	sub    $0x4,%esp
801029f1:	53                   	push   %ebx
801029f2:	50                   	push   %eax
801029f3:	68 44 6d 10 80       	push   $0x80106d44
801029f8:	e8 0a dc ff ff       	call   80100607 <cprintf>
  idtinit();       // load idt register
801029fd:	e8 b5 25 00 00       	call   80104fb7 <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
80102a02:	e8 9d 07 00 00       	call   801031a4 <mycpu>
80102a07:	89 c2                	mov    %eax,%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80102a09:	b8 01 00 00 00       	mov    $0x1,%eax
80102a0e:	f0 87 82 a0 00 00 00 	lock xchg %eax,0xa0(%edx)
  scheduler();     // start running processes
80102a15:	e8 7e 0a 00 00       	call   80103498 <scheduler>

80102a1a <mpenter>:
{
80102a1a:	55                   	push   %ebp
80102a1b:	89 e5                	mov    %esp,%ebp
80102a1d:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
80102a20:	e8 be 36 00 00       	call   801060e3 <switchkvm>
  seginit();
80102a25:	e8 44 34 00 00       	call   80105e6e <seginit>
  lapicinit();
80102a2a:	e8 25 f8 ff ff       	call   80102254 <lapicinit>
  mpmain();
80102a2f:	e8 a7 ff ff ff       	call   801029db <mpmain>

80102a34 <main>:
{
80102a34:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80102a38:	83 e4 f0             	and    $0xfffffff0,%esp
80102a3b:	ff 71 fc             	push   -0x4(%ecx)
80102a3e:	55                   	push   %ebp
80102a3f:	89 e5                	mov    %esp,%ebp
80102a41:	51                   	push   %ecx
80102a42:	83 ec 0c             	sub    $0xc,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80102a45:	68 00 00 40 80       	push   $0x80400000
80102a4a:	68 f0 56 11 80       	push   $0x801156f0
80102a4f:	e8 fd f5 ff ff       	call   80102051 <kinit1>
  kvmalloc();      // kernel page table
80102a54:	e8 56 3b 00 00       	call   801065af <kvmalloc>
  mpinit();        // detect other processors
80102a59:	e8 c1 01 00 00       	call   80102c1f <mpinit>
  lapicinit();     // interrupt controller
80102a5e:	e8 f1 f7 ff ff       	call   80102254 <lapicinit>
  seginit();       // segment descriptors
80102a63:	e8 06 34 00 00       	call   80105e6e <seginit>
  picinit();       // disable pic
80102a68:	e8 88 02 00 00       	call   80102cf5 <picinit>
  ioapicinit();    // another interrupt controller
80102a6d:	e8 6b f4 ff ff       	call   80101edd <ioapicinit>
  consoleinit();   // console hardware
80102a72:	e8 13 de ff ff       	call   8010088a <consoleinit>
  uartinit();      // serial port
80102a77:	e8 e2 27 00 00       	call   8010525e <uartinit>
  pinit();         // process table
80102a7c:	e8 09 07 00 00       	call   8010318a <pinit>
  tvinit();        // trap vectors
80102a81:	e8 2c 24 00 00       	call   80104eb2 <tvinit>
  binit();         // buffer cache
80102a86:	e8 69 d6 ff ff       	call   801000f4 <binit>
  fileinit();      // file table
80102a8b:	e8 73 e1 ff ff       	call   80100c03 <fileinit>
  ideinit();       // disk 
80102a90:	e8 54 f2 ff ff       	call   80101ce9 <ideinit>
  startothers();   // start other processors
80102a95:	e8 b2 fe ff ff       	call   8010294c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80102a9a:	83 c4 08             	add    $0x8,%esp
80102a9d:	68 00 00 00 8e       	push   $0x8e000000
80102aa2:	68 00 00 40 80       	push   $0x80400000
80102aa7:	e8 d7 f5 ff ff       	call   80102083 <kinit2>
  userinit();      // first user process
80102aac:	e8 8d 07 00 00       	call   8010323e <userinit>
  mpmain();        // finish this processor's setup
80102ab1:	e8 25 ff ff ff       	call   801029db <mpmain>

80102ab6 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80102ab6:	55                   	push   %ebp
80102ab7:	89 e5                	mov    %esp,%ebp
80102ab9:	56                   	push   %esi
80102aba:	53                   	push   %ebx
80102abb:	89 c6                	mov    %eax,%esi
  int i, sum;

  sum = 0;
80102abd:	b8 00 00 00 00       	mov    $0x0,%eax
  for(i=0; i<len; i++)
80102ac2:	b9 00 00 00 00       	mov    $0x0,%ecx
80102ac7:	eb 09                	jmp    80102ad2 <sum+0x1c>
    sum += addr[i];
80102ac9:	0f b6 1c 0e          	movzbl (%esi,%ecx,1),%ebx
80102acd:	01 d8                	add    %ebx,%eax
  for(i=0; i<len; i++)
80102acf:	83 c1 01             	add    $0x1,%ecx
80102ad2:	39 d1                	cmp    %edx,%ecx
80102ad4:	7c f3                	jl     80102ac9 <sum+0x13>
  return sum;
}
80102ad6:	5b                   	pop    %ebx
80102ad7:	5e                   	pop    %esi
80102ad8:	5d                   	pop    %ebp
80102ad9:	c3                   	ret    

80102ada <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80102ada:	55                   	push   %ebp
80102adb:	89 e5                	mov    %esp,%ebp
80102add:	56                   	push   %esi
80102ade:	53                   	push   %ebx
  uchar *e, *p, *addr;

  addr = P2V(a);
80102adf:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80102ae5:	89 f3                	mov    %esi,%ebx
  e = addr+len;
80102ae7:	01 d6                	add    %edx,%esi
  for(p = addr; p < e; p += sizeof(struct mp))
80102ae9:	eb 03                	jmp    80102aee <mpsearch1+0x14>
80102aeb:	83 c3 10             	add    $0x10,%ebx
80102aee:	39 f3                	cmp    %esi,%ebx
80102af0:	73 29                	jae    80102b1b <mpsearch1+0x41>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80102af2:	83 ec 04             	sub    $0x4,%esp
80102af5:	6a 04                	push   $0x4
80102af7:	68 58 6d 10 80       	push   $0x80106d58
80102afc:	53                   	push   %ebx
80102afd:	e8 6d 12 00 00       	call   80103d6f <memcmp>
80102b02:	83 c4 10             	add    $0x10,%esp
80102b05:	85 c0                	test   %eax,%eax
80102b07:	75 e2                	jne    80102aeb <mpsearch1+0x11>
80102b09:	ba 10 00 00 00       	mov    $0x10,%edx
80102b0e:	89 d8                	mov    %ebx,%eax
80102b10:	e8 a1 ff ff ff       	call   80102ab6 <sum>
80102b15:	84 c0                	test   %al,%al
80102b17:	75 d2                	jne    80102aeb <mpsearch1+0x11>
80102b19:	eb 05                	jmp    80102b20 <mpsearch1+0x46>
      return (struct mp*)p;
  return 0;
80102b1b:	bb 00 00 00 00       	mov    $0x0,%ebx
}
80102b20:	89 d8                	mov    %ebx,%eax
80102b22:	8d 65 f8             	lea    -0x8(%ebp),%esp
80102b25:	5b                   	pop    %ebx
80102b26:	5e                   	pop    %esi
80102b27:	5d                   	pop    %ebp
80102b28:	c3                   	ret    

80102b29 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80102b29:	55                   	push   %ebp
80102b2a:	89 e5                	mov    %esp,%ebp
80102b2c:	83 ec 08             	sub    $0x8,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80102b2f:	0f b6 05 0f 04 00 80 	movzbl 0x8000040f,%eax
80102b36:	c1 e0 08             	shl    $0x8,%eax
80102b39:	0f b6 15 0e 04 00 80 	movzbl 0x8000040e,%edx
80102b40:	09 d0                	or     %edx,%eax
80102b42:	c1 e0 04             	shl    $0x4,%eax
80102b45:	74 1f                	je     80102b66 <mpsearch+0x3d>
    if((mp = mpsearch1(p, 1024)))
80102b47:	ba 00 04 00 00       	mov    $0x400,%edx
80102b4c:	e8 89 ff ff ff       	call   80102ada <mpsearch1>
80102b51:	85 c0                	test   %eax,%eax
80102b53:	75 0f                	jne    80102b64 <mpsearch+0x3b>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
    if((mp = mpsearch1(p-1024, 1024)))
      return mp;
  }
  return mpsearch1(0xF0000, 0x10000);
80102b55:	ba 00 00 01 00       	mov    $0x10000,%edx
80102b5a:	b8 00 00 0f 00       	mov    $0xf0000,%eax
80102b5f:	e8 76 ff ff ff       	call   80102ada <mpsearch1>
}
80102b64:	c9                   	leave  
80102b65:	c3                   	ret    
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80102b66:	0f b6 05 14 04 00 80 	movzbl 0x80000414,%eax
80102b6d:	c1 e0 08             	shl    $0x8,%eax
80102b70:	0f b6 15 13 04 00 80 	movzbl 0x80000413,%edx
80102b77:	09 d0                	or     %edx,%eax
80102b79:	c1 e0 0a             	shl    $0xa,%eax
    if((mp = mpsearch1(p-1024, 1024)))
80102b7c:	2d 00 04 00 00       	sub    $0x400,%eax
80102b81:	ba 00 04 00 00       	mov    $0x400,%edx
80102b86:	e8 4f ff ff ff       	call   80102ada <mpsearch1>
80102b8b:	85 c0                	test   %eax,%eax
80102b8d:	75 d5                	jne    80102b64 <mpsearch+0x3b>
80102b8f:	eb c4                	jmp    80102b55 <mpsearch+0x2c>

80102b91 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80102b91:	55                   	push   %ebp
80102b92:	89 e5                	mov    %esp,%ebp
80102b94:	57                   	push   %edi
80102b95:	56                   	push   %esi
80102b96:	53                   	push   %ebx
80102b97:	83 ec 1c             	sub    $0x1c,%esp
80102b9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80102b9d:	e8 87 ff ff ff       	call   80102b29 <mpsearch>
80102ba2:	89 c3                	mov    %eax,%ebx
80102ba4:	85 c0                	test   %eax,%eax
80102ba6:	74 5a                	je     80102c02 <mpconfig+0x71>
80102ba8:	8b 70 04             	mov    0x4(%eax),%esi
80102bab:	85 f6                	test   %esi,%esi
80102bad:	74 57                	je     80102c06 <mpconfig+0x75>
    return 0;
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80102baf:	8d be 00 00 00 80    	lea    -0x80000000(%esi),%edi
  if(memcmp(conf, "PCMP", 4) != 0)
80102bb5:	83 ec 04             	sub    $0x4,%esp
80102bb8:	6a 04                	push   $0x4
80102bba:	68 5d 6d 10 80       	push   $0x80106d5d
80102bbf:	57                   	push   %edi
80102bc0:	e8 aa 11 00 00       	call   80103d6f <memcmp>
80102bc5:	83 c4 10             	add    $0x10,%esp
80102bc8:	85 c0                	test   %eax,%eax
80102bca:	75 3e                	jne    80102c0a <mpconfig+0x79>
    return 0;
  if(conf->version != 1 && conf->version != 4)
80102bcc:	0f b6 86 06 00 00 80 	movzbl -0x7ffffffa(%esi),%eax
80102bd3:	3c 01                	cmp    $0x1,%al
80102bd5:	0f 95 c2             	setne  %dl
80102bd8:	3c 04                	cmp    $0x4,%al
80102bda:	0f 95 c0             	setne  %al
80102bdd:	84 c2                	test   %al,%dl
80102bdf:	75 30                	jne    80102c11 <mpconfig+0x80>
    return 0;
  if(sum((uchar*)conf, conf->length) != 0)
80102be1:	0f b7 96 04 00 00 80 	movzwl -0x7ffffffc(%esi),%edx
80102be8:	89 f8                	mov    %edi,%eax
80102bea:	e8 c7 fe ff ff       	call   80102ab6 <sum>
80102bef:	84 c0                	test   %al,%al
80102bf1:	75 25                	jne    80102c18 <mpconfig+0x87>
    return 0;
  *pmp = mp;
80102bf3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102bf6:	89 18                	mov    %ebx,(%eax)
  return conf;
}
80102bf8:	89 f8                	mov    %edi,%eax
80102bfa:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102bfd:	5b                   	pop    %ebx
80102bfe:	5e                   	pop    %esi
80102bff:	5f                   	pop    %edi
80102c00:	5d                   	pop    %ebp
80102c01:	c3                   	ret    
    return 0;
80102c02:	89 c7                	mov    %eax,%edi
80102c04:	eb f2                	jmp    80102bf8 <mpconfig+0x67>
80102c06:	89 f7                	mov    %esi,%edi
80102c08:	eb ee                	jmp    80102bf8 <mpconfig+0x67>
    return 0;
80102c0a:	bf 00 00 00 00       	mov    $0x0,%edi
80102c0f:	eb e7                	jmp    80102bf8 <mpconfig+0x67>
    return 0;
80102c11:	bf 00 00 00 00       	mov    $0x0,%edi
80102c16:	eb e0                	jmp    80102bf8 <mpconfig+0x67>
    return 0;
80102c18:	bf 00 00 00 00       	mov    $0x0,%edi
80102c1d:	eb d9                	jmp    80102bf8 <mpconfig+0x67>

80102c1f <mpinit>:

void
mpinit(void)
{
80102c1f:	55                   	push   %ebp
80102c20:	89 e5                	mov    %esp,%ebp
80102c22:	57                   	push   %edi
80102c23:	56                   	push   %esi
80102c24:	53                   	push   %ebx
80102c25:	83 ec 1c             	sub    $0x1c,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80102c28:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80102c2b:	e8 61 ff ff ff       	call   80102b91 <mpconfig>
80102c30:	85 c0                	test   %eax,%eax
80102c32:	74 19                	je     80102c4d <mpinit+0x2e>
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
80102c34:	8b 50 24             	mov    0x24(%eax),%edx
80102c37:	89 15 80 16 11 80    	mov    %edx,0x80111680
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102c3d:	8d 50 2c             	lea    0x2c(%eax),%edx
80102c40:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
80102c44:	01 c1                	add    %eax,%ecx
  ismp = 1;
80102c46:	bb 01 00 00 00       	mov    $0x1,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102c4b:	eb 20                	jmp    80102c6d <mpinit+0x4e>
    panic("Expect to run on an SMP");
80102c4d:	83 ec 0c             	sub    $0xc,%esp
80102c50:	68 62 6d 10 80       	push   $0x80106d62
80102c55:	e8 ee d6 ff ff       	call   80100348 <panic>
    switch(*p){
80102c5a:	bb 00 00 00 00       	mov    $0x0,%ebx
80102c5f:	eb 0c                	jmp    80102c6d <mpinit+0x4e>
80102c61:	83 e8 03             	sub    $0x3,%eax
80102c64:	3c 01                	cmp    $0x1,%al
80102c66:	76 1a                	jbe    80102c82 <mpinit+0x63>
80102c68:	bb 00 00 00 00       	mov    $0x0,%ebx
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80102c6d:	39 ca                	cmp    %ecx,%edx
80102c6f:	73 4d                	jae    80102cbe <mpinit+0x9f>
    switch(*p){
80102c71:	0f b6 02             	movzbl (%edx),%eax
80102c74:	3c 02                	cmp    $0x2,%al
80102c76:	74 38                	je     80102cb0 <mpinit+0x91>
80102c78:	77 e7                	ja     80102c61 <mpinit+0x42>
80102c7a:	84 c0                	test   %al,%al
80102c7c:	74 09                	je     80102c87 <mpinit+0x68>
80102c7e:	3c 01                	cmp    $0x1,%al
80102c80:	75 d8                	jne    80102c5a <mpinit+0x3b>
      p += sizeof(struct mpioapic);
      continue;
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80102c82:	83 c2 08             	add    $0x8,%edx
      continue;
80102c85:	eb e6                	jmp    80102c6d <mpinit+0x4e>
      if(ncpu < NCPU) {
80102c87:	8b 35 84 17 11 80    	mov    0x80111784,%esi
80102c8d:	83 fe 07             	cmp    $0x7,%esi
80102c90:	7f 19                	jg     80102cab <mpinit+0x8c>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80102c92:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102c96:	69 fe b0 00 00 00    	imul   $0xb0,%esi,%edi
80102c9c:	88 87 a0 17 11 80    	mov    %al,-0x7feee860(%edi)
        ncpu++;
80102ca2:	83 c6 01             	add    $0x1,%esi
80102ca5:	89 35 84 17 11 80    	mov    %esi,0x80111784
      p += sizeof(struct mpproc);
80102cab:	83 c2 14             	add    $0x14,%edx
      continue;
80102cae:	eb bd                	jmp    80102c6d <mpinit+0x4e>
      ioapicid = ioapic->apicno;
80102cb0:	0f b6 42 01          	movzbl 0x1(%edx),%eax
80102cb4:	a2 80 17 11 80       	mov    %al,0x80111780
      p += sizeof(struct mpioapic);
80102cb9:	83 c2 08             	add    $0x8,%edx
      continue;
80102cbc:	eb af                	jmp    80102c6d <mpinit+0x4e>
    default:
      ismp = 0;
      break;
    }
  }
  if(!ismp)
80102cbe:	85 db                	test   %ebx,%ebx
80102cc0:	74 26                	je     80102ce8 <mpinit+0xc9>
    panic("Didn't find a suitable machine");

  if(mp->imcrp){
80102cc2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80102cc5:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
80102cc9:	74 15                	je     80102ce0 <mpinit+0xc1>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102ccb:	b8 70 00 00 00       	mov    $0x70,%eax
80102cd0:	ba 22 00 00 00       	mov    $0x22,%edx
80102cd5:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102cd6:	ba 23 00 00 00       	mov    $0x23,%edx
80102cdb:	ec                   	in     (%dx),%al
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80102cdc:	83 c8 01             	or     $0x1,%eax
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102cdf:	ee                   	out    %al,(%dx)
  }
}
80102ce0:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ce3:	5b                   	pop    %ebx
80102ce4:	5e                   	pop    %esi
80102ce5:	5f                   	pop    %edi
80102ce6:	5d                   	pop    %ebp
80102ce7:	c3                   	ret    
    panic("Didn't find a suitable machine");
80102ce8:	83 ec 0c             	sub    $0xc,%esp
80102ceb:	68 7c 6d 10 80       	push   $0x80106d7c
80102cf0:	e8 53 d6 ff ff       	call   80100348 <panic>

80102cf5 <picinit>:
80102cf5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102cfa:	ba 21 00 00 00       	mov    $0x21,%edx
80102cff:	ee                   	out    %al,(%dx)
80102d00:	ba a1 00 00 00       	mov    $0xa1,%edx
80102d05:	ee                   	out    %al,(%dx)
picinit(void)
{
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
  outb(IO_PIC2+1, 0xFF);
}
80102d06:	c3                   	ret    

80102d07 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80102d07:	55                   	push   %ebp
80102d08:	89 e5                	mov    %esp,%ebp
80102d0a:	57                   	push   %edi
80102d0b:	56                   	push   %esi
80102d0c:	53                   	push   %ebx
80102d0d:	83 ec 0c             	sub    $0xc,%esp
80102d10:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102d13:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct pipe *p;

  p = 0;
  *f0 = *f1 = 0;
80102d16:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
80102d1c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80102d22:	e8 f6 de ff ff       	call   80100c1d <filealloc>
80102d27:	89 03                	mov    %eax,(%ebx)
80102d29:	85 c0                	test   %eax,%eax
80102d2b:	0f 84 88 00 00 00    	je     80102db9 <pipealloc+0xb2>
80102d31:	e8 e7 de ff ff       	call   80100c1d <filealloc>
80102d36:	89 06                	mov    %eax,(%esi)
80102d38:	85 c0                	test   %eax,%eax
80102d3a:	74 7d                	je     80102db9 <pipealloc+0xb2>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80102d3c:	e8 62 f3 ff ff       	call   801020a3 <kalloc>
80102d41:	89 c7                	mov    %eax,%edi
80102d43:	85 c0                	test   %eax,%eax
80102d45:	74 72                	je     80102db9 <pipealloc+0xb2>
    goto bad;
  p->readopen = 1;
80102d47:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80102d4e:	00 00 00 
  p->writeopen = 1;
80102d51:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80102d58:	00 00 00 
  p->nwrite = 0;
80102d5b:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80102d62:	00 00 00 
  p->nread = 0;
80102d65:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80102d6c:	00 00 00 
  initlock(&p->lock, "pipe");
80102d6f:	83 ec 08             	sub    $0x8,%esp
80102d72:	68 9b 6d 10 80       	push   $0x80106d9b
80102d77:	50                   	push   %eax
80102d78:	e8 c7 0d 00 00       	call   80103b44 <initlock>
  (*f0)->type = FD_PIPE;
80102d7d:	8b 03                	mov    (%ebx),%eax
80102d7f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80102d85:	8b 03                	mov    (%ebx),%eax
80102d87:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80102d8b:	8b 03                	mov    (%ebx),%eax
80102d8d:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80102d91:	8b 03                	mov    (%ebx),%eax
80102d93:	89 78 0c             	mov    %edi,0xc(%eax)
  (*f1)->type = FD_PIPE;
80102d96:	8b 06                	mov    (%esi),%eax
80102d98:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80102d9e:	8b 06                	mov    (%esi),%eax
80102da0:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80102da4:	8b 06                	mov    (%esi),%eax
80102da6:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80102daa:	8b 06                	mov    (%esi),%eax
80102dac:	89 78 0c             	mov    %edi,0xc(%eax)
  return 0;
80102daf:	83 c4 10             	add    $0x10,%esp
80102db2:	b8 00 00 00 00       	mov    $0x0,%eax
80102db7:	eb 29                	jmp    80102de2 <pipealloc+0xdb>

//PAGEBREAK: 20
 bad:
  if(p)
    kfree((char*)p);
  if(*f0)
80102db9:	8b 03                	mov    (%ebx),%eax
80102dbb:	85 c0                	test   %eax,%eax
80102dbd:	74 0c                	je     80102dcb <pipealloc+0xc4>
    fileclose(*f0);
80102dbf:	83 ec 0c             	sub    $0xc,%esp
80102dc2:	50                   	push   %eax
80102dc3:	e8 fb de ff ff       	call   80100cc3 <fileclose>
80102dc8:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80102dcb:	8b 06                	mov    (%esi),%eax
80102dcd:	85 c0                	test   %eax,%eax
80102dcf:	74 19                	je     80102dea <pipealloc+0xe3>
    fileclose(*f1);
80102dd1:	83 ec 0c             	sub    $0xc,%esp
80102dd4:	50                   	push   %eax
80102dd5:	e8 e9 de ff ff       	call   80100cc3 <fileclose>
80102dda:	83 c4 10             	add    $0x10,%esp
  return -1;
80102ddd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102de2:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102de5:	5b                   	pop    %ebx
80102de6:	5e                   	pop    %esi
80102de7:	5f                   	pop    %edi
80102de8:	5d                   	pop    %ebp
80102de9:	c3                   	ret    
  return -1;
80102dea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102def:	eb f1                	jmp    80102de2 <pipealloc+0xdb>

80102df1 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80102df1:	55                   	push   %ebp
80102df2:	89 e5                	mov    %esp,%ebp
80102df4:	53                   	push   %ebx
80102df5:	83 ec 10             	sub    $0x10,%esp
80102df8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&p->lock);
80102dfb:	53                   	push   %ebx
80102dfc:	e8 7f 0e 00 00       	call   80103c80 <acquire>
  if(writable){
80102e01:	83 c4 10             	add    $0x10,%esp
80102e04:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102e08:	74 3f                	je     80102e49 <pipeclose+0x58>
    p->writeopen = 0;
80102e0a:	c7 83 40 02 00 00 00 	movl   $0x0,0x240(%ebx)
80102e11:	00 00 00 
    wakeup(&p->nread);
80102e14:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102e1a:	83 ec 0c             	sub    $0xc,%esp
80102e1d:	50                   	push   %eax
80102e1e:	e8 c2 0a 00 00       	call   801038e5 <wakeup>
80102e23:	83 c4 10             	add    $0x10,%esp
  } else {
    p->readopen = 0;
    wakeup(&p->nwrite);
  }
  if(p->readopen == 0 && p->writeopen == 0){
80102e26:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102e2d:	75 09                	jne    80102e38 <pipeclose+0x47>
80102e2f:	83 bb 40 02 00 00 00 	cmpl   $0x0,0x240(%ebx)
80102e36:	74 2f                	je     80102e67 <pipeclose+0x76>
    release(&p->lock);
    kfree((char*)p);
  } else
    release(&p->lock);
80102e38:	83 ec 0c             	sub    $0xc,%esp
80102e3b:	53                   	push   %ebx
80102e3c:	e8 a4 0e 00 00       	call   80103ce5 <release>
80102e41:	83 c4 10             	add    $0x10,%esp
}
80102e44:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80102e47:	c9                   	leave  
80102e48:	c3                   	ret    
    p->readopen = 0;
80102e49:	c7 83 3c 02 00 00 00 	movl   $0x0,0x23c(%ebx)
80102e50:	00 00 00 
    wakeup(&p->nwrite);
80102e53:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102e59:	83 ec 0c             	sub    $0xc,%esp
80102e5c:	50                   	push   %eax
80102e5d:	e8 83 0a 00 00       	call   801038e5 <wakeup>
80102e62:	83 c4 10             	add    $0x10,%esp
80102e65:	eb bf                	jmp    80102e26 <pipeclose+0x35>
    release(&p->lock);
80102e67:	83 ec 0c             	sub    $0xc,%esp
80102e6a:	53                   	push   %ebx
80102e6b:	e8 75 0e 00 00       	call   80103ce5 <release>
    kfree((char*)p);
80102e70:	89 1c 24             	mov    %ebx,(%esp)
80102e73:	e8 14 f1 ff ff       	call   80101f8c <kfree>
80102e78:	83 c4 10             	add    $0x10,%esp
80102e7b:	eb c7                	jmp    80102e44 <pipeclose+0x53>

80102e7d <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80102e7d:	55                   	push   %ebp
80102e7e:	89 e5                	mov    %esp,%ebp
80102e80:	57                   	push   %edi
80102e81:	56                   	push   %esi
80102e82:	53                   	push   %ebx
80102e83:	83 ec 18             	sub    $0x18,%esp
80102e86:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102e89:	8b 75 10             	mov    0x10(%ebp),%esi
  int i;

  acquire(&p->lock);
80102e8c:	53                   	push   %ebx
80102e8d:	e8 ee 0d 00 00       	call   80103c80 <acquire>
  for(i = 0; i < n; i++){
80102e92:	83 c4 10             	add    $0x10,%esp
80102e95:	bf 00 00 00 00       	mov    $0x0,%edi
80102e9a:	39 f7                	cmp    %esi,%edi
80102e9c:	7c 40                	jl     80102ede <pipewrite+0x61>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80102e9e:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ea4:	83 ec 0c             	sub    $0xc,%esp
80102ea7:	50                   	push   %eax
80102ea8:	e8 38 0a 00 00       	call   801038e5 <wakeup>
  release(&p->lock);
80102ead:	89 1c 24             	mov    %ebx,(%esp)
80102eb0:	e8 30 0e 00 00       	call   80103ce5 <release>
  return n;
80102eb5:	83 c4 10             	add    $0x10,%esp
80102eb8:	89 f0                	mov    %esi,%eax
80102eba:	eb 5c                	jmp    80102f18 <pipewrite+0x9b>
      wakeup(&p->nread);
80102ebc:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102ec2:	83 ec 0c             	sub    $0xc,%esp
80102ec5:	50                   	push   %eax
80102ec6:	e8 1a 0a 00 00       	call   801038e5 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80102ecb:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102ed1:	83 c4 08             	add    $0x8,%esp
80102ed4:	53                   	push   %ebx
80102ed5:	50                   	push   %eax
80102ed6:	e8 a2 08 00 00       	call   8010377d <sleep>
80102edb:	83 c4 10             	add    $0x10,%esp
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80102ede:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
80102ee4:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102eea:	05 00 02 00 00       	add    $0x200,%eax
80102eef:	39 c2                	cmp    %eax,%edx
80102ef1:	75 2d                	jne    80102f20 <pipewrite+0xa3>
      if(p->readopen == 0 || myproc()->killed){
80102ef3:	83 bb 3c 02 00 00 00 	cmpl   $0x0,0x23c(%ebx)
80102efa:	74 0b                	je     80102f07 <pipewrite+0x8a>
80102efc:	e8 1a 03 00 00       	call   8010321b <myproc>
80102f01:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102f05:	74 b5                	je     80102ebc <pipewrite+0x3f>
        release(&p->lock);
80102f07:	83 ec 0c             	sub    $0xc,%esp
80102f0a:	53                   	push   %ebx
80102f0b:	e8 d5 0d 00 00       	call   80103ce5 <release>
        return -1;
80102f10:	83 c4 10             	add    $0x10,%esp
80102f13:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80102f18:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102f1b:	5b                   	pop    %ebx
80102f1c:	5e                   	pop    %esi
80102f1d:	5f                   	pop    %edi
80102f1e:	5d                   	pop    %ebp
80102f1f:	c3                   	ret    
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80102f20:	8d 42 01             	lea    0x1(%edx),%eax
80102f23:	89 83 38 02 00 00    	mov    %eax,0x238(%ebx)
80102f29:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102f2f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102f32:	0f b6 04 38          	movzbl (%eax,%edi,1),%eax
80102f36:	88 44 13 34          	mov    %al,0x34(%ebx,%edx,1)
  for(i = 0; i < n; i++){
80102f3a:	83 c7 01             	add    $0x1,%edi
80102f3d:	e9 58 ff ff ff       	jmp    80102e9a <pipewrite+0x1d>

80102f42 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80102f42:	55                   	push   %ebp
80102f43:	89 e5                	mov    %esp,%ebp
80102f45:	57                   	push   %edi
80102f46:	56                   	push   %esi
80102f47:	53                   	push   %ebx
80102f48:	83 ec 18             	sub    $0x18,%esp
80102f4b:	8b 5d 08             	mov    0x8(%ebp),%ebx
80102f4e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  int i;

  acquire(&p->lock);
80102f51:	53                   	push   %ebx
80102f52:	e8 29 0d 00 00       	call   80103c80 <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80102f57:	83 c4 10             	add    $0x10,%esp
80102f5a:	eb 13                	jmp    80102f6f <piperead+0x2d>
    if(myproc()->killed){
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80102f5c:	8d 83 34 02 00 00    	lea    0x234(%ebx),%eax
80102f62:	83 ec 08             	sub    $0x8,%esp
80102f65:	53                   	push   %ebx
80102f66:	50                   	push   %eax
80102f67:	e8 11 08 00 00       	call   8010377d <sleep>
80102f6c:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80102f6f:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
80102f75:	39 83 34 02 00 00    	cmp    %eax,0x234(%ebx)
80102f7b:	75 78                	jne    80102ff5 <piperead+0xb3>
80102f7d:	8b b3 40 02 00 00    	mov    0x240(%ebx),%esi
80102f83:	85 f6                	test   %esi,%esi
80102f85:	74 37                	je     80102fbe <piperead+0x7c>
    if(myproc()->killed){
80102f87:	e8 8f 02 00 00       	call   8010321b <myproc>
80102f8c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80102f90:	74 ca                	je     80102f5c <piperead+0x1a>
      release(&p->lock);
80102f92:	83 ec 0c             	sub    $0xc,%esp
80102f95:	53                   	push   %ebx
80102f96:	e8 4a 0d 00 00       	call   80103ce5 <release>
      return -1;
80102f9b:	83 c4 10             	add    $0x10,%esp
80102f9e:	be ff ff ff ff       	mov    $0xffffffff,%esi
80102fa3:	eb 46                	jmp    80102feb <piperead+0xa9>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(p->nread == p->nwrite)
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80102fa5:	8d 50 01             	lea    0x1(%eax),%edx
80102fa8:	89 93 34 02 00 00    	mov    %edx,0x234(%ebx)
80102fae:	25 ff 01 00 00       	and    $0x1ff,%eax
80102fb3:	0f b6 44 03 34       	movzbl 0x34(%ebx,%eax,1),%eax
80102fb8:	88 04 37             	mov    %al,(%edi,%esi,1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80102fbb:	83 c6 01             	add    $0x1,%esi
80102fbe:	3b 75 10             	cmp    0x10(%ebp),%esi
80102fc1:	7d 0e                	jge    80102fd1 <piperead+0x8f>
    if(p->nread == p->nwrite)
80102fc3:	8b 83 34 02 00 00    	mov    0x234(%ebx),%eax
80102fc9:	3b 83 38 02 00 00    	cmp    0x238(%ebx),%eax
80102fcf:	75 d4                	jne    80102fa5 <piperead+0x63>
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80102fd1:	8d 83 38 02 00 00    	lea    0x238(%ebx),%eax
80102fd7:	83 ec 0c             	sub    $0xc,%esp
80102fda:	50                   	push   %eax
80102fdb:	e8 05 09 00 00       	call   801038e5 <wakeup>
  release(&p->lock);
80102fe0:	89 1c 24             	mov    %ebx,(%esp)
80102fe3:	e8 fd 0c 00 00       	call   80103ce5 <release>
  return i;
80102fe8:	83 c4 10             	add    $0x10,%esp
}
80102feb:	89 f0                	mov    %esi,%eax
80102fed:	8d 65 f4             	lea    -0xc(%ebp),%esp
80102ff0:	5b                   	pop    %ebx
80102ff1:	5e                   	pop    %esi
80102ff2:	5f                   	pop    %edi
80102ff3:	5d                   	pop    %ebp
80102ff4:	c3                   	ret    
80102ff5:	be 00 00 00 00       	mov    $0x0,%esi
80102ffa:	eb c2                	jmp    80102fbe <piperead+0x7c>

80102ffc <wakeup1>:
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80102ffc:	ba 74 1d 11 80       	mov    $0x80111d74,%edx
80103001:	eb 06                	jmp    80103009 <wakeup1+0xd>
80103003:	81 c2 84 00 00 00    	add    $0x84,%edx
80103009:	81 fa 74 3e 11 80    	cmp    $0x80113e74,%edx
8010300f:	73 14                	jae    80103025 <wakeup1+0x29>
    if(p->state == SLEEPING && p->chan == chan)
80103011:	83 7a 0c 02          	cmpl   $0x2,0xc(%edx)
80103015:	75 ec                	jne    80103003 <wakeup1+0x7>
80103017:	39 42 20             	cmp    %eax,0x20(%edx)
8010301a:	75 e7                	jne    80103003 <wakeup1+0x7>
      p->state = RUNNABLE;
8010301c:	c7 42 0c 03 00 00 00 	movl   $0x3,0xc(%edx)
80103023:	eb de                	jmp    80103003 <wakeup1+0x7>
}
80103025:	c3                   	ret    

80103026 <allocproc>:
{
80103026:	55                   	push   %ebp
80103027:	89 e5                	mov    %esp,%ebp
80103029:	53                   	push   %ebx
8010302a:	83 ec 10             	sub    $0x10,%esp
  acquire(&ptable.lock);
8010302d:	68 40 1d 11 80       	push   $0x80111d40
80103032:	e8 49 0c 00 00       	call   80103c80 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80103037:	83 c4 10             	add    $0x10,%esp
8010303a:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
8010303f:	eb 06                	jmp    80103047 <allocproc+0x21>
80103041:	81 c3 84 00 00 00    	add    $0x84,%ebx
80103047:	81 fb 74 3e 11 80    	cmp    $0x80113e74,%ebx
8010304d:	73 76                	jae    801030c5 <allocproc+0x9f>
    if(p->state == UNUSED)
8010304f:	83 7b 0c 00          	cmpl   $0x0,0xc(%ebx)
80103053:	75 ec                	jne    80103041 <allocproc+0x1b>
  p->state = EMBRYO;
80103055:	c7 43 0c 01 00 00 00 	movl   $0x1,0xc(%ebx)
  p->pid = nextpid++;
8010305c:	a1 04 a0 10 80       	mov    0x8010a004,%eax
80103061:	8d 50 01             	lea    0x1(%eax),%edx
80103064:	89 15 04 a0 10 80    	mov    %edx,0x8010a004
8010306a:	89 43 10             	mov    %eax,0x10(%ebx)
  release(&ptable.lock);
8010306d:	83 ec 0c             	sub    $0xc,%esp
80103070:	68 40 1d 11 80       	push   $0x80111d40
80103075:	e8 6b 0c 00 00       	call   80103ce5 <release>
  if((p->kstack = kalloc()) == 0){
8010307a:	e8 24 f0 ff ff       	call   801020a3 <kalloc>
8010307f:	89 43 08             	mov    %eax,0x8(%ebx)
80103082:	83 c4 10             	add    $0x10,%esp
80103085:	85 c0                	test   %eax,%eax
80103087:	74 53                	je     801030dc <allocproc+0xb6>
  sp -= sizeof *p->tf;
80103089:	8d 90 b4 0f 00 00    	lea    0xfb4(%eax),%edx
  p->tf = (struct trapframe*)sp;
8010308f:	89 53 18             	mov    %edx,0x18(%ebx)
  *(uint*)sp = (uint)trapret;
80103092:	c7 80 b0 0f 00 00 a7 	movl   $0x80104ea7,0xfb0(%eax)
80103099:	4e 10 80 
  sp -= sizeof *p->context;
8010309c:	05 9c 0f 00 00       	add    $0xf9c,%eax
  p->context = (struct context*)sp;
801030a1:	89 43 1c             	mov    %eax,0x1c(%ebx)
  memset(p->context, 0, sizeof *p->context);
801030a4:	83 ec 04             	sub    $0x4,%esp
801030a7:	6a 14                	push   $0x14
801030a9:	6a 00                	push   $0x0
801030ab:	50                   	push   %eax
801030ac:	e8 7b 0c 00 00       	call   80103d2c <memset>
  p->context->eip = (uint)forkret;
801030b1:	8b 43 1c             	mov    0x1c(%ebx),%eax
801030b4:	c7 40 10 e7 30 10 80 	movl   $0x801030e7,0x10(%eax)
  return p;
801030bb:	83 c4 10             	add    $0x10,%esp
}
801030be:	89 d8                	mov    %ebx,%eax
801030c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801030c3:	c9                   	leave  
801030c4:	c3                   	ret    
  release(&ptable.lock);
801030c5:	83 ec 0c             	sub    $0xc,%esp
801030c8:	68 40 1d 11 80       	push   $0x80111d40
801030cd:	e8 13 0c 00 00       	call   80103ce5 <release>
  return 0;
801030d2:	83 c4 10             	add    $0x10,%esp
801030d5:	bb 00 00 00 00       	mov    $0x0,%ebx
801030da:	eb e2                	jmp    801030be <allocproc+0x98>
    p->state = UNUSED;
801030dc:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return 0;
801030e3:	89 c3                	mov    %eax,%ebx
801030e5:	eb d7                	jmp    801030be <allocproc+0x98>

801030e7 <forkret>:
{
801030e7:	55                   	push   %ebp
801030e8:	89 e5                	mov    %esp,%ebp
801030ea:	83 ec 14             	sub    $0x14,%esp
  release(&ptable.lock);
801030ed:	68 40 1d 11 80       	push   $0x80111d40
801030f2:	e8 ee 0b 00 00       	call   80103ce5 <release>
  if (first) {
801030f7:	83 c4 10             	add    $0x10,%esp
801030fa:	83 3d 00 a0 10 80 00 	cmpl   $0x0,0x8010a000
80103101:	75 02                	jne    80103105 <forkret+0x1e>
}
80103103:	c9                   	leave  
80103104:	c3                   	ret    
    first = 0;
80103105:	c7 05 00 a0 10 80 00 	movl   $0x0,0x8010a000
8010310c:	00 00 00 
    iinit(ROOTDEV);
8010310f:	83 ec 0c             	sub    $0xc,%esp
80103112:	6a 01                	push   $0x1
80103114:	e8 c1 e1 ff ff       	call   801012da <iinit>
    initlog(ROOTDEV);
80103119:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80103120:	e8 10 f6 ff ff       	call   80102735 <initlog>
80103125:	83 c4 10             	add    $0x10,%esp
}
80103128:	eb d9                	jmp    80103103 <forkret+0x1c>

8010312a <iterate_ptable>:
struct pstat* iterate_ptable(struct pstat* pstate){
8010312a:	55                   	push   %ebp
8010312b:	89 e5                	mov    %esp,%ebp
8010312d:	53                   	push   %ebx
8010312e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  int i = 0;
80103131:	ba 00 00 00 00       	mov    $0x0,%edx
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103136:	b8 74 1d 11 80       	mov    $0x80111d74,%eax
8010313b:	eb 30                	jmp    8010316d <iterate_ptable+0x43>
        pstate->inuse[i] = 0;
8010313d:	c7 04 91 00 00 00 00 	movl   $0x0,(%ecx,%edx,4)
      pstate->tickets[i] = p->priority;
80103144:	8b 58 7c             	mov    0x7c(%eax),%ebx
80103147:	89 9c 91 00 01 00 00 	mov    %ebx,0x100(%ecx,%edx,4)
      pstate->pid[i] = p->pid;
8010314e:	8b 58 10             	mov    0x10(%eax),%ebx
80103151:	89 9c 91 00 02 00 00 	mov    %ebx,0x200(%ecx,%edx,4)
      pstate->ticks[i] = p->run_ticks;
80103158:	8b 98 80 00 00 00    	mov    0x80(%eax),%ebx
8010315e:	89 9c 91 00 03 00 00 	mov    %ebx,0x300(%ecx,%edx,4)
      i++;
80103165:	83 c2 01             	add    $0x1,%edx
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103168:	05 84 00 00 00       	add    $0x84,%eax
8010316d:	3d 74 3e 11 80       	cmp    $0x80113e74,%eax
80103172:	73 0f                	jae    80103183 <iterate_ptable+0x59>
      if (p->state != UNUSED){
80103174:	83 78 0c 00          	cmpl   $0x0,0xc(%eax)
80103178:	74 c3                	je     8010313d <iterate_ptable+0x13>
        pstate->inuse[i] = 1;
8010317a:	c7 04 91 01 00 00 00 	movl   $0x1,(%ecx,%edx,4)
80103181:	eb c1                	jmp    80103144 <iterate_ptable+0x1a>
}
80103183:	89 c8                	mov    %ecx,%eax
80103185:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103188:	c9                   	leave  
80103189:	c3                   	ret    

8010318a <pinit>:
{
8010318a:	55                   	push   %ebp
8010318b:	89 e5                	mov    %esp,%ebp
8010318d:	83 ec 10             	sub    $0x10,%esp
  initlock(&ptable.lock, "ptable");
80103190:	68 a0 6d 10 80       	push   $0x80106da0
80103195:	68 40 1d 11 80       	push   $0x80111d40
8010319a:	e8 a5 09 00 00       	call   80103b44 <initlock>
}
8010319f:	83 c4 10             	add    $0x10,%esp
801031a2:	c9                   	leave  
801031a3:	c3                   	ret    

801031a4 <mycpu>:
{
801031a4:	55                   	push   %ebp
801031a5:	89 e5                	mov    %esp,%ebp
801031a7:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801031aa:	9c                   	pushf  
801031ab:	58                   	pop    %eax
  if(readeflags()&FL_IF)
801031ac:	f6 c4 02             	test   $0x2,%ah
801031af:	75 28                	jne    801031d9 <mycpu+0x35>
  apicid = lapicid();
801031b1:	e8 aa f1 ff ff       	call   80102360 <lapicid>
  for (i = 0; i < ncpu; ++i) {
801031b6:	ba 00 00 00 00       	mov    $0x0,%edx
801031bb:	39 15 84 17 11 80    	cmp    %edx,0x80111784
801031c1:	7e 23                	jle    801031e6 <mycpu+0x42>
    if (cpus[i].apicid == apicid)
801031c3:	69 ca b0 00 00 00    	imul   $0xb0,%edx,%ecx
801031c9:	0f b6 89 a0 17 11 80 	movzbl -0x7feee860(%ecx),%ecx
801031d0:	39 c1                	cmp    %eax,%ecx
801031d2:	74 1f                	je     801031f3 <mycpu+0x4f>
  for (i = 0; i < ncpu; ++i) {
801031d4:	83 c2 01             	add    $0x1,%edx
801031d7:	eb e2                	jmp    801031bb <mycpu+0x17>
    panic("mycpu called with interrupts enabled\n");
801031d9:	83 ec 0c             	sub    $0xc,%esp
801031dc:	68 84 6e 10 80       	push   $0x80106e84
801031e1:	e8 62 d1 ff ff       	call   80100348 <panic>
  panic("unknown apicid\n");
801031e6:	83 ec 0c             	sub    $0xc,%esp
801031e9:	68 a7 6d 10 80       	push   $0x80106da7
801031ee:	e8 55 d1 ff ff       	call   80100348 <panic>
      return &cpus[i];
801031f3:	69 c2 b0 00 00 00    	imul   $0xb0,%edx,%eax
801031f9:	05 a0 17 11 80       	add    $0x801117a0,%eax
}
801031fe:	c9                   	leave  
801031ff:	c3                   	ret    

80103200 <cpuid>:
cpuid() {
80103200:	55                   	push   %ebp
80103201:	89 e5                	mov    %esp,%ebp
80103203:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
80103206:	e8 99 ff ff ff       	call   801031a4 <mycpu>
8010320b:	2d a0 17 11 80       	sub    $0x801117a0,%eax
80103210:	c1 f8 04             	sar    $0x4,%eax
80103213:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
80103219:	c9                   	leave  
8010321a:	c3                   	ret    

8010321b <myproc>:
myproc(void) {
8010321b:	55                   	push   %ebp
8010321c:	89 e5                	mov    %esp,%ebp
8010321e:	53                   	push   %ebx
8010321f:	83 ec 04             	sub    $0x4,%esp
  pushcli();
80103222:	e8 7e 09 00 00       	call   80103ba5 <pushcli>
  c = mycpu();
80103227:	e8 78 ff ff ff       	call   801031a4 <mycpu>
  p = c->proc;
8010322c:	8b 98 ac 00 00 00    	mov    0xac(%eax),%ebx
  popcli();
80103232:	e8 aa 09 00 00       	call   80103be1 <popcli>
}
80103237:	89 d8                	mov    %ebx,%eax
80103239:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010323c:	c9                   	leave  
8010323d:	c3                   	ret    

8010323e <userinit>:
{
8010323e:	55                   	push   %ebp
8010323f:	89 e5                	mov    %esp,%ebp
80103241:	53                   	push   %ebx
80103242:	83 ec 04             	sub    $0x4,%esp
  p = allocproc();
80103245:	e8 dc fd ff ff       	call   80103026 <allocproc>
8010324a:	89 c3                	mov    %eax,%ebx
  initproc = p;
8010324c:	a3 74 3e 11 80       	mov    %eax,0x80113e74
  if((p->pgdir = setupkvm()) == 0)
80103251:	e8 eb 32 00 00       	call   80106541 <setupkvm>
80103256:	89 43 04             	mov    %eax,0x4(%ebx)
80103259:	85 c0                	test   %eax,%eax
8010325b:	0f 84 b8 00 00 00    	je     80103319 <userinit+0xdb>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80103261:	83 ec 04             	sub    $0x4,%esp
80103264:	68 2c 00 00 00       	push   $0x2c
80103269:	68 60 a4 10 80       	push   $0x8010a460
8010326e:	50                   	push   %eax
8010326f:	e8 dd 2f 00 00       	call   80106251 <inituvm>
  p->sz = PGSIZE;
80103274:	c7 03 00 10 00 00    	movl   $0x1000,(%ebx)
  memset(p->tf, 0, sizeof(*p->tf));
8010327a:	8b 43 18             	mov    0x18(%ebx),%eax
8010327d:	83 c4 0c             	add    $0xc,%esp
80103280:	6a 4c                	push   $0x4c
80103282:	6a 00                	push   $0x0
80103284:	50                   	push   %eax
80103285:	e8 a2 0a 00 00       	call   80103d2c <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010328a:	8b 43 18             	mov    0x18(%ebx),%eax
8010328d:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80103293:	8b 43 18             	mov    0x18(%ebx),%eax
80103296:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010329c:	8b 43 18             	mov    0x18(%ebx),%eax
8010329f:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801032a3:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
801032a7:	8b 43 18             	mov    0x18(%ebx),%eax
801032aa:	0f b7 50 2c          	movzwl 0x2c(%eax),%edx
801032ae:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801032b2:	8b 43 18             	mov    0x18(%ebx),%eax
801032b5:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801032bc:	8b 43 18             	mov    0x18(%ebx),%eax
801032bf:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801032c6:	8b 43 18             	mov    0x18(%ebx),%eax
801032c9:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)
  safestrcpy(p->name, "initcode", sizeof(p->name));
801032d0:	8d 43 6c             	lea    0x6c(%ebx),%eax
801032d3:	83 c4 0c             	add    $0xc,%esp
801032d6:	6a 10                	push   $0x10
801032d8:	68 d0 6d 10 80       	push   $0x80106dd0
801032dd:	50                   	push   %eax
801032de:	e8 b5 0b 00 00       	call   80103e98 <safestrcpy>
  p->cwd = namei("/");
801032e3:	c7 04 24 d9 6d 10 80 	movl   $0x80106dd9,(%esp)
801032ea:	e8 de e8 ff ff       	call   80101bcd <namei>
801032ef:	89 43 68             	mov    %eax,0x68(%ebx)
  acquire(&ptable.lock);
801032f2:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
801032f9:	e8 82 09 00 00       	call   80103c80 <acquire>
  p->state = RUNNABLE;
801032fe:	c7 43 0c 03 00 00 00 	movl   $0x3,0xc(%ebx)
  release(&ptable.lock);
80103305:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
8010330c:	e8 d4 09 00 00       	call   80103ce5 <release>
}
80103311:	83 c4 10             	add    $0x10,%esp
80103314:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103317:	c9                   	leave  
80103318:	c3                   	ret    
    panic("userinit: out of memory?");
80103319:	83 ec 0c             	sub    $0xc,%esp
8010331c:	68 b7 6d 10 80       	push   $0x80106db7
80103321:	e8 22 d0 ff ff       	call   80100348 <panic>

80103326 <growproc>:
{
80103326:	55                   	push   %ebp
80103327:	89 e5                	mov    %esp,%ebp
80103329:	56                   	push   %esi
8010332a:	53                   	push   %ebx
8010332b:	8b 75 08             	mov    0x8(%ebp),%esi
  struct proc *curproc = myproc();
8010332e:	e8 e8 fe ff ff       	call   8010321b <myproc>
80103333:	89 c3                	mov    %eax,%ebx
  sz = curproc->sz;
80103335:	8b 00                	mov    (%eax),%eax
  if(n > 0){
80103337:	85 f6                	test   %esi,%esi
80103339:	7f 1c                	jg     80103357 <growproc+0x31>
  } else if(n < 0){
8010333b:	78 37                	js     80103374 <growproc+0x4e>
  curproc->sz = sz;
8010333d:	89 03                	mov    %eax,(%ebx)
  switchuvm(curproc);
8010333f:	83 ec 0c             	sub    $0xc,%esp
80103342:	53                   	push   %ebx
80103343:	e8 a9 2d 00 00       	call   801060f1 <switchuvm>
  return 0;
80103348:	83 c4 10             	add    $0x10,%esp
8010334b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103350:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103353:	5b                   	pop    %ebx
80103354:	5e                   	pop    %esi
80103355:	5d                   	pop    %ebp
80103356:	c3                   	ret    
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103357:	83 ec 04             	sub    $0x4,%esp
8010335a:	01 c6                	add    %eax,%esi
8010335c:	56                   	push   %esi
8010335d:	50                   	push   %eax
8010335e:	ff 73 04             	push   0x4(%ebx)
80103361:	e8 81 30 00 00       	call   801063e7 <allocuvm>
80103366:	83 c4 10             	add    $0x10,%esp
80103369:	85 c0                	test   %eax,%eax
8010336b:	75 d0                	jne    8010333d <growproc+0x17>
      return -1;
8010336d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103372:	eb dc                	jmp    80103350 <growproc+0x2a>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80103374:	83 ec 04             	sub    $0x4,%esp
80103377:	01 c6                	add    %eax,%esi
80103379:	56                   	push   %esi
8010337a:	50                   	push   %eax
8010337b:	ff 73 04             	push   0x4(%ebx)
8010337e:	e8 d2 2f 00 00       	call   80106355 <deallocuvm>
80103383:	83 c4 10             	add    $0x10,%esp
80103386:	85 c0                	test   %eax,%eax
80103388:	75 b3                	jne    8010333d <growproc+0x17>
      return -1;
8010338a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010338f:	eb bf                	jmp    80103350 <growproc+0x2a>

80103391 <fork>:
{
80103391:	55                   	push   %ebp
80103392:	89 e5                	mov    %esp,%ebp
80103394:	57                   	push   %edi
80103395:	56                   	push   %esi
80103396:	53                   	push   %ebx
80103397:	83 ec 1c             	sub    $0x1c,%esp
  struct proc *curproc = myproc();
8010339a:	e8 7c fe ff ff       	call   8010321b <myproc>
8010339f:	89 c3                	mov    %eax,%ebx
  if((np = allocproc()) == 0){
801033a1:	e8 80 fc ff ff       	call   80103026 <allocproc>
801033a6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801033a9:	85 c0                	test   %eax,%eax
801033ab:	0f 84 e0 00 00 00    	je     80103491 <fork+0x100>
801033b1:	89 c7                	mov    %eax,%edi
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801033b3:	83 ec 08             	sub    $0x8,%esp
801033b6:	ff 33                	push   (%ebx)
801033b8:	ff 73 04             	push   0x4(%ebx)
801033bb:	e8 32 32 00 00       	call   801065f2 <copyuvm>
801033c0:	89 47 04             	mov    %eax,0x4(%edi)
801033c3:	83 c4 10             	add    $0x10,%esp
801033c6:	85 c0                	test   %eax,%eax
801033c8:	74 2a                	je     801033f4 <fork+0x63>
  np->sz = curproc->sz;
801033ca:	8b 03                	mov    (%ebx),%eax
801033cc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801033cf:	89 01                	mov    %eax,(%ecx)
  np->parent = curproc;
801033d1:	89 c8                	mov    %ecx,%eax
801033d3:	89 59 14             	mov    %ebx,0x14(%ecx)
  *np->tf = *curproc->tf;
801033d6:	8b 73 18             	mov    0x18(%ebx),%esi
801033d9:	8b 79 18             	mov    0x18(%ecx),%edi
801033dc:	b9 13 00 00 00       	mov    $0x13,%ecx
801033e1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  np->tf->eax = 0;
801033e3:	8b 40 18             	mov    0x18(%eax),%eax
801033e6:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
  for(i = 0; i < NOFILE; i++)
801033ed:	be 00 00 00 00       	mov    $0x0,%esi
801033f2:	eb 29                	jmp    8010341d <fork+0x8c>
    kfree(np->kstack);
801033f4:	83 ec 0c             	sub    $0xc,%esp
801033f7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
801033fa:	ff 73 08             	push   0x8(%ebx)
801033fd:	e8 8a eb ff ff       	call   80101f8c <kfree>
    np->kstack = 0;
80103402:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
    np->state = UNUSED;
80103409:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
    return -1;
80103410:	83 c4 10             	add    $0x10,%esp
80103413:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103418:	eb 6d                	jmp    80103487 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
8010341a:	83 c6 01             	add    $0x1,%esi
8010341d:	83 fe 0f             	cmp    $0xf,%esi
80103420:	7f 1d                	jg     8010343f <fork+0xae>
    if(curproc->ofile[i])
80103422:	8b 44 b3 28          	mov    0x28(%ebx,%esi,4),%eax
80103426:	85 c0                	test   %eax,%eax
80103428:	74 f0                	je     8010341a <fork+0x89>
      np->ofile[i] = filedup(curproc->ofile[i]);
8010342a:	83 ec 0c             	sub    $0xc,%esp
8010342d:	50                   	push   %eax
8010342e:	e8 4b d8 ff ff       	call   80100c7e <filedup>
80103433:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80103436:	89 44 b2 28          	mov    %eax,0x28(%edx,%esi,4)
8010343a:	83 c4 10             	add    $0x10,%esp
8010343d:	eb db                	jmp    8010341a <fork+0x89>
  np->cwd = idup(curproc->cwd);
8010343f:	83 ec 0c             	sub    $0xc,%esp
80103442:	ff 73 68             	push   0x68(%ebx)
80103445:	e8 f5 e0 ff ff       	call   8010153f <idup>
8010344a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
8010344d:	89 47 68             	mov    %eax,0x68(%edi)
  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
80103450:	83 c3 6c             	add    $0x6c,%ebx
80103453:	8d 47 6c             	lea    0x6c(%edi),%eax
80103456:	83 c4 0c             	add    $0xc,%esp
80103459:	6a 10                	push   $0x10
8010345b:	53                   	push   %ebx
8010345c:	50                   	push   %eax
8010345d:	e8 36 0a 00 00       	call   80103e98 <safestrcpy>
  pid = np->pid;
80103462:	8b 5f 10             	mov    0x10(%edi),%ebx
  acquire(&ptable.lock);
80103465:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
8010346c:	e8 0f 08 00 00       	call   80103c80 <acquire>
  np->state = RUNNABLE;
80103471:	c7 47 0c 03 00 00 00 	movl   $0x3,0xc(%edi)
  release(&ptable.lock);
80103478:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
8010347f:	e8 61 08 00 00       	call   80103ce5 <release>
  return pid;
80103484:	83 c4 10             	add    $0x10,%esp
}
80103487:	89 d8                	mov    %ebx,%eax
80103489:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010348c:	5b                   	pop    %ebx
8010348d:	5e                   	pop    %esi
8010348e:	5f                   	pop    %edi
8010348f:	5d                   	pop    %ebp
80103490:	c3                   	ret    
    return -1;
80103491:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80103496:	eb ef                	jmp    80103487 <fork+0xf6>

80103498 <scheduler>:
{
80103498:	55                   	push   %ebp
80103499:	89 e5                	mov    %esp,%ebp
8010349b:	57                   	push   %edi
8010349c:	56                   	push   %esi
8010349d:	53                   	push   %ebx
8010349e:	83 ec 0c             	sub    $0xc,%esp
  struct cpu *c = mycpu();
801034a1:	e8 fe fc ff ff       	call   801031a4 <mycpu>
801034a6:	89 c6                	mov    %eax,%esi
  c->proc = 0;
801034a8:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801034af:	00 00 00 
801034b2:	e9 08 01 00 00       	jmp    801035bf <scheduler+0x127>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801034b7:	81 c3 84 00 00 00    	add    $0x84,%ebx
801034bd:	81 fb 74 3e 11 80    	cmp    $0x80113e74,%ebx
801034c3:	73 59                	jae    8010351e <scheduler+0x86>
      if(p->state != RUNNABLE || p->priority == 0)
801034c5:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
801034c9:	75 ec                	jne    801034b7 <scheduler+0x1f>
801034cb:	83 7b 7c 00          	cmpl   $0x0,0x7c(%ebx)
801034cf:	74 e6                	je     801034b7 <scheduler+0x1f>
      c->proc = p;
801034d1:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
      switchuvm(p);
801034d7:	83 ec 0c             	sub    $0xc,%esp
801034da:	53                   	push   %ebx
801034db:	e8 11 2c 00 00       	call   801060f1 <switchuvm>
      p->state = RUNNING;
801034e0:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
      p->run_ticks++;
801034e7:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
801034ed:	83 c0 01             	add    $0x1,%eax
801034f0:	89 83 80 00 00 00    	mov    %eax,0x80(%ebx)
      swtch(&(c->scheduler), p->context);
801034f6:	83 c4 08             	add    $0x8,%esp
801034f9:	ff 73 1c             	push   0x1c(%ebx)
801034fc:	8d 46 04             	lea    0x4(%esi),%eax
801034ff:	50                   	push   %eax
80103500:	e8 e8 09 00 00       	call   80103eed <swtch>
      switchkvm();
80103505:	e8 d9 2b 00 00       	call   801060e3 <switchkvm>
      c->proc = 0;
8010350a:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
80103511:	00 00 00 
80103514:	83 c4 10             	add    $0x10,%esp
      first_loop = 1;
80103517:	bf 01 00 00 00       	mov    $0x1,%edi
8010351c:	eb 99                	jmp    801034b7 <scheduler+0x1f>
    release(&ptable.lock);
8010351e:	83 ec 0c             	sub    $0xc,%esp
80103521:	68 40 1d 11 80       	push   $0x80111d40
80103526:	e8 ba 07 00 00       	call   80103ce5 <release>
    if (first_loop == 0){
8010352b:	83 c4 10             	add    $0x10,%esp
8010352e:	85 ff                	test   %edi,%edi
80103530:	0f 85 89 00 00 00    	jne    801035bf <scheduler+0x127>
        acquire(&ptable.lock);
80103536:	83 ec 0c             	sub    $0xc,%esp
80103539:	68 40 1d 11 80       	push   $0x80111d40
8010353e:	e8 3d 07 00 00       	call   80103c80 <acquire>
        for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103543:	83 c4 10             	add    $0x10,%esp
80103546:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
8010354b:	eb 06                	jmp    80103553 <scheduler+0xbb>
8010354d:	81 c3 84 00 00 00    	add    $0x84,%ebx
80103553:	81 fb 74 3e 11 80    	cmp    $0x80113e74,%ebx
80103559:	73 54                	jae    801035af <scheduler+0x117>
        if(p->state != RUNNABLE || p->priority == 1)
8010355b:	83 7b 0c 03          	cmpl   $0x3,0xc(%ebx)
8010355f:	75 ec                	jne    8010354d <scheduler+0xb5>
80103561:	83 7b 7c 01          	cmpl   $0x1,0x7c(%ebx)
80103565:	74 e6                	je     8010354d <scheduler+0xb5>
        c->proc = p;
80103567:	89 9e ac 00 00 00    	mov    %ebx,0xac(%esi)
        switchuvm(p);
8010356d:	83 ec 0c             	sub    $0xc,%esp
80103570:	53                   	push   %ebx
80103571:	e8 7b 2b 00 00       	call   801060f1 <switchuvm>
        p->state = RUNNING;
80103576:	c7 43 0c 04 00 00 00 	movl   $0x4,0xc(%ebx)
        p->run_ticks++;
8010357d:	8b 83 80 00 00 00    	mov    0x80(%ebx),%eax
80103583:	83 c0 01             	add    $0x1,%eax
80103586:	89 83 80 00 00 00    	mov    %eax,0x80(%ebx)
        swtch(&(c->scheduler), p->context);
8010358c:	83 c4 08             	add    $0x8,%esp
8010358f:	ff 73 1c             	push   0x1c(%ebx)
80103592:	8d 46 04             	lea    0x4(%esi),%eax
80103595:	50                   	push   %eax
80103596:	e8 52 09 00 00       	call   80103eed <swtch>
        switchkvm();
8010359b:	e8 43 2b 00 00       	call   801060e3 <switchkvm>
        c->proc = 0;
801035a0:	c7 86 ac 00 00 00 00 	movl   $0x0,0xac(%esi)
801035a7:	00 00 00 
801035aa:	83 c4 10             	add    $0x10,%esp
801035ad:	eb 9e                	jmp    8010354d <scheduler+0xb5>
        release(&ptable.lock);
801035af:	83 ec 0c             	sub    $0xc,%esp
801035b2:	68 40 1d 11 80       	push   $0x80111d40
801035b7:	e8 29 07 00 00       	call   80103ce5 <release>
801035bc:	83 c4 10             	add    $0x10,%esp
  asm volatile("sti");
801035bf:	fb                   	sti    
    acquire(&ptable.lock);
801035c0:	83 ec 0c             	sub    $0xc,%esp
801035c3:	68 40 1d 11 80       	push   $0x80111d40
801035c8:	e8 b3 06 00 00       	call   80103c80 <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035cd:	83 c4 10             	add    $0x10,%esp
    int first_loop = 0;
801035d0:	bf 00 00 00 00       	mov    $0x0,%edi
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801035d5:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
801035da:	e9 de fe ff ff       	jmp    801034bd <scheduler+0x25>

801035df <sched>:
{
801035df:	55                   	push   %ebp
801035e0:	89 e5                	mov    %esp,%ebp
801035e2:	56                   	push   %esi
801035e3:	53                   	push   %ebx
  struct proc *p = myproc();
801035e4:	e8 32 fc ff ff       	call   8010321b <myproc>
801035e9:	89 c3                	mov    %eax,%ebx
  if(!holding(&ptable.lock))
801035eb:	83 ec 0c             	sub    $0xc,%esp
801035ee:	68 40 1d 11 80       	push   $0x80111d40
801035f3:	e8 49 06 00 00       	call   80103c41 <holding>
801035f8:	83 c4 10             	add    $0x10,%esp
801035fb:	85 c0                	test   %eax,%eax
801035fd:	74 4f                	je     8010364e <sched+0x6f>
  if(mycpu()->ncli != 1)
801035ff:	e8 a0 fb ff ff       	call   801031a4 <mycpu>
80103604:	83 b8 a4 00 00 00 01 	cmpl   $0x1,0xa4(%eax)
8010360b:	75 4e                	jne    8010365b <sched+0x7c>
  if(p->state == RUNNING)
8010360d:	83 7b 0c 04          	cmpl   $0x4,0xc(%ebx)
80103611:	74 55                	je     80103668 <sched+0x89>
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103613:	9c                   	pushf  
80103614:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103615:	f6 c4 02             	test   $0x2,%ah
80103618:	75 5b                	jne    80103675 <sched+0x96>
  intena = mycpu()->intena;
8010361a:	e8 85 fb ff ff       	call   801031a4 <mycpu>
8010361f:	8b b0 a8 00 00 00    	mov    0xa8(%eax),%esi
  swtch(&p->context, mycpu()->scheduler);
80103625:	e8 7a fb ff ff       	call   801031a4 <mycpu>
8010362a:	83 ec 08             	sub    $0x8,%esp
8010362d:	ff 70 04             	push   0x4(%eax)
80103630:	83 c3 1c             	add    $0x1c,%ebx
80103633:	53                   	push   %ebx
80103634:	e8 b4 08 00 00       	call   80103eed <swtch>
  mycpu()->intena = intena;
80103639:	e8 66 fb ff ff       	call   801031a4 <mycpu>
8010363e:	89 b0 a8 00 00 00    	mov    %esi,0xa8(%eax)
}
80103644:	83 c4 10             	add    $0x10,%esp
80103647:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010364a:	5b                   	pop    %ebx
8010364b:	5e                   	pop    %esi
8010364c:	5d                   	pop    %ebp
8010364d:	c3                   	ret    
    panic("sched ptable.lock");
8010364e:	83 ec 0c             	sub    $0xc,%esp
80103651:	68 db 6d 10 80       	push   $0x80106ddb
80103656:	e8 ed cc ff ff       	call   80100348 <panic>
    panic("sched locks");
8010365b:	83 ec 0c             	sub    $0xc,%esp
8010365e:	68 ed 6d 10 80       	push   $0x80106ded
80103663:	e8 e0 cc ff ff       	call   80100348 <panic>
    panic("sched running");
80103668:	83 ec 0c             	sub    $0xc,%esp
8010366b:	68 f9 6d 10 80       	push   $0x80106df9
80103670:	e8 d3 cc ff ff       	call   80100348 <panic>
    panic("sched interruptible");
80103675:	83 ec 0c             	sub    $0xc,%esp
80103678:	68 07 6e 10 80       	push   $0x80106e07
8010367d:	e8 c6 cc ff ff       	call   80100348 <panic>

80103682 <exit>:
{
80103682:	55                   	push   %ebp
80103683:	89 e5                	mov    %esp,%ebp
80103685:	56                   	push   %esi
80103686:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103687:	e8 8f fb ff ff       	call   8010321b <myproc>
  if(curproc == initproc)
8010368c:	39 05 74 3e 11 80    	cmp    %eax,0x80113e74
80103692:	74 09                	je     8010369d <exit+0x1b>
80103694:	89 c6                	mov    %eax,%esi
  for(fd = 0; fd < NOFILE; fd++){
80103696:	bb 00 00 00 00       	mov    $0x0,%ebx
8010369b:	eb 24                	jmp    801036c1 <exit+0x3f>
    panic("init exiting");
8010369d:	83 ec 0c             	sub    $0xc,%esp
801036a0:	68 1b 6e 10 80       	push   $0x80106e1b
801036a5:	e8 9e cc ff ff       	call   80100348 <panic>
      fileclose(curproc->ofile[fd]);
801036aa:	83 ec 0c             	sub    $0xc,%esp
801036ad:	50                   	push   %eax
801036ae:	e8 10 d6 ff ff       	call   80100cc3 <fileclose>
      curproc->ofile[fd] = 0;
801036b3:	c7 44 9e 28 00 00 00 	movl   $0x0,0x28(%esi,%ebx,4)
801036ba:	00 
801036bb:	83 c4 10             	add    $0x10,%esp
  for(fd = 0; fd < NOFILE; fd++){
801036be:	83 c3 01             	add    $0x1,%ebx
801036c1:	83 fb 0f             	cmp    $0xf,%ebx
801036c4:	7f 0a                	jg     801036d0 <exit+0x4e>
    if(curproc->ofile[fd]){
801036c6:	8b 44 9e 28          	mov    0x28(%esi,%ebx,4),%eax
801036ca:	85 c0                	test   %eax,%eax
801036cc:	75 dc                	jne    801036aa <exit+0x28>
801036ce:	eb ee                	jmp    801036be <exit+0x3c>
  begin_op();
801036d0:	e8 a9 f0 ff ff       	call   8010277e <begin_op>
  iput(curproc->cwd);
801036d5:	83 ec 0c             	sub    $0xc,%esp
801036d8:	ff 76 68             	push   0x68(%esi)
801036db:	e8 96 df ff ff       	call   80101676 <iput>
  end_op();
801036e0:	e8 13 f1 ff ff       	call   801027f8 <end_op>
  curproc->cwd = 0;
801036e5:	c7 46 68 00 00 00 00 	movl   $0x0,0x68(%esi)
  acquire(&ptable.lock);
801036ec:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
801036f3:	e8 88 05 00 00       	call   80103c80 <acquire>
  wakeup1(curproc->parent);
801036f8:	8b 46 14             	mov    0x14(%esi),%eax
801036fb:	e8 fc f8 ff ff       	call   80102ffc <wakeup1>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103700:	83 c4 10             	add    $0x10,%esp
80103703:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
80103708:	eb 06                	jmp    80103710 <exit+0x8e>
8010370a:	81 c3 84 00 00 00    	add    $0x84,%ebx
80103710:	81 fb 74 3e 11 80    	cmp    $0x80113e74,%ebx
80103716:	73 1a                	jae    80103732 <exit+0xb0>
    if(p->parent == curproc){
80103718:	39 73 14             	cmp    %esi,0x14(%ebx)
8010371b:	75 ed                	jne    8010370a <exit+0x88>
      p->parent = initproc;
8010371d:	a1 74 3e 11 80       	mov    0x80113e74,%eax
80103722:	89 43 14             	mov    %eax,0x14(%ebx)
      if(p->state == ZOMBIE)
80103725:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
80103729:	75 df                	jne    8010370a <exit+0x88>
        wakeup1(initproc);
8010372b:	e8 cc f8 ff ff       	call   80102ffc <wakeup1>
80103730:	eb d8                	jmp    8010370a <exit+0x88>
  curproc->state = ZOMBIE;
80103732:	c7 46 0c 05 00 00 00 	movl   $0x5,0xc(%esi)
  sched();
80103739:	e8 a1 fe ff ff       	call   801035df <sched>
  panic("zombie exit");
8010373e:	83 ec 0c             	sub    $0xc,%esp
80103741:	68 28 6e 10 80       	push   $0x80106e28
80103746:	e8 fd cb ff ff       	call   80100348 <panic>

8010374b <yield>:
{
8010374b:	55                   	push   %ebp
8010374c:	89 e5                	mov    %esp,%ebp
8010374e:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80103751:	68 40 1d 11 80       	push   $0x80111d40
80103756:	e8 25 05 00 00       	call   80103c80 <acquire>
  myproc()->state = RUNNABLE;
8010375b:	e8 bb fa ff ff       	call   8010321b <myproc>
80103760:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80103767:	e8 73 fe ff ff       	call   801035df <sched>
  release(&ptable.lock);
8010376c:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
80103773:	e8 6d 05 00 00       	call   80103ce5 <release>
}
80103778:	83 c4 10             	add    $0x10,%esp
8010377b:	c9                   	leave  
8010377c:	c3                   	ret    

8010377d <sleep>:
{
8010377d:	55                   	push   %ebp
8010377e:	89 e5                	mov    %esp,%ebp
80103780:	56                   	push   %esi
80103781:	53                   	push   %ebx
80103782:	8b 75 0c             	mov    0xc(%ebp),%esi
  struct proc *p = myproc();
80103785:	e8 91 fa ff ff       	call   8010321b <myproc>
  if(p == 0)
8010378a:	85 c0                	test   %eax,%eax
8010378c:	74 66                	je     801037f4 <sleep+0x77>
8010378e:	89 c3                	mov    %eax,%ebx
  if(lk == 0)
80103790:	85 f6                	test   %esi,%esi
80103792:	74 6d                	je     80103801 <sleep+0x84>
  if(lk != &ptable.lock){  //DOC: sleeplock0
80103794:	81 fe 40 1d 11 80    	cmp    $0x80111d40,%esi
8010379a:	74 18                	je     801037b4 <sleep+0x37>
    acquire(&ptable.lock);  //DOC: sleeplock1
8010379c:	83 ec 0c             	sub    $0xc,%esp
8010379f:	68 40 1d 11 80       	push   $0x80111d40
801037a4:	e8 d7 04 00 00       	call   80103c80 <acquire>
    release(lk);
801037a9:	89 34 24             	mov    %esi,(%esp)
801037ac:	e8 34 05 00 00       	call   80103ce5 <release>
801037b1:	83 c4 10             	add    $0x10,%esp
  p->chan = chan;
801037b4:	8b 45 08             	mov    0x8(%ebp),%eax
801037b7:	89 43 20             	mov    %eax,0x20(%ebx)
  p->state = SLEEPING;
801037ba:	c7 43 0c 02 00 00 00 	movl   $0x2,0xc(%ebx)
  sched();
801037c1:	e8 19 fe ff ff       	call   801035df <sched>
  p->chan = 0;
801037c6:	c7 43 20 00 00 00 00 	movl   $0x0,0x20(%ebx)
  if(lk != &ptable.lock){  //DOC: sleeplock2
801037cd:	81 fe 40 1d 11 80    	cmp    $0x80111d40,%esi
801037d3:	74 18                	je     801037ed <sleep+0x70>
    release(&ptable.lock);
801037d5:	83 ec 0c             	sub    $0xc,%esp
801037d8:	68 40 1d 11 80       	push   $0x80111d40
801037dd:	e8 03 05 00 00       	call   80103ce5 <release>
    acquire(lk);
801037e2:	89 34 24             	mov    %esi,(%esp)
801037e5:	e8 96 04 00 00       	call   80103c80 <acquire>
801037ea:	83 c4 10             	add    $0x10,%esp
}
801037ed:	8d 65 f8             	lea    -0x8(%ebp),%esp
801037f0:	5b                   	pop    %ebx
801037f1:	5e                   	pop    %esi
801037f2:	5d                   	pop    %ebp
801037f3:	c3                   	ret    
    panic("sleep");
801037f4:	83 ec 0c             	sub    $0xc,%esp
801037f7:	68 34 6e 10 80       	push   $0x80106e34
801037fc:	e8 47 cb ff ff       	call   80100348 <panic>
    panic("sleep without lk");
80103801:	83 ec 0c             	sub    $0xc,%esp
80103804:	68 3a 6e 10 80       	push   $0x80106e3a
80103809:	e8 3a cb ff ff       	call   80100348 <panic>

8010380e <wait>:
{
8010380e:	55                   	push   %ebp
8010380f:	89 e5                	mov    %esp,%ebp
80103811:	56                   	push   %esi
80103812:	53                   	push   %ebx
  struct proc *curproc = myproc();
80103813:	e8 03 fa ff ff       	call   8010321b <myproc>
80103818:	89 c6                	mov    %eax,%esi
  acquire(&ptable.lock);
8010381a:	83 ec 0c             	sub    $0xc,%esp
8010381d:	68 40 1d 11 80       	push   $0x80111d40
80103822:	e8 59 04 00 00       	call   80103c80 <acquire>
80103827:	83 c4 10             	add    $0x10,%esp
    havekids = 0;
8010382a:	b8 00 00 00 00       	mov    $0x0,%eax
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010382f:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
80103834:	eb 5e                	jmp    80103894 <wait+0x86>
        pid = p->pid;
80103836:	8b 73 10             	mov    0x10(%ebx),%esi
        kfree(p->kstack);
80103839:	83 ec 0c             	sub    $0xc,%esp
8010383c:	ff 73 08             	push   0x8(%ebx)
8010383f:	e8 48 e7 ff ff       	call   80101f8c <kfree>
        p->kstack = 0;
80103844:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
        freevm(p->pgdir);
8010384b:	83 c4 04             	add    $0x4,%esp
8010384e:	ff 73 04             	push   0x4(%ebx)
80103851:	e8 7b 2c 00 00       	call   801064d1 <freevm>
        p->pid = 0;
80103856:	c7 43 10 00 00 00 00 	movl   $0x0,0x10(%ebx)
        p->parent = 0;
8010385d:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
        p->name[0] = 0;
80103864:	c6 43 6c 00          	movb   $0x0,0x6c(%ebx)
        p->killed = 0;
80103868:	c7 43 24 00 00 00 00 	movl   $0x0,0x24(%ebx)
        p->state = UNUSED;
8010386f:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
        release(&ptable.lock);
80103876:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
8010387d:	e8 63 04 00 00       	call   80103ce5 <release>
        return pid;
80103882:	83 c4 10             	add    $0x10,%esp
}
80103885:	89 f0                	mov    %esi,%eax
80103887:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010388a:	5b                   	pop    %ebx
8010388b:	5e                   	pop    %esi
8010388c:	5d                   	pop    %ebp
8010388d:	c3                   	ret    
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010388e:	81 c3 84 00 00 00    	add    $0x84,%ebx
80103894:	81 fb 74 3e 11 80    	cmp    $0x80113e74,%ebx
8010389a:	73 12                	jae    801038ae <wait+0xa0>
      if(p->parent != curproc)
8010389c:	39 73 14             	cmp    %esi,0x14(%ebx)
8010389f:	75 ed                	jne    8010388e <wait+0x80>
      if(p->state == ZOMBIE){
801038a1:	83 7b 0c 05          	cmpl   $0x5,0xc(%ebx)
801038a5:	74 8f                	je     80103836 <wait+0x28>
      havekids = 1;
801038a7:	b8 01 00 00 00       	mov    $0x1,%eax
801038ac:	eb e0                	jmp    8010388e <wait+0x80>
    if(!havekids || curproc->killed){
801038ae:	85 c0                	test   %eax,%eax
801038b0:	74 06                	je     801038b8 <wait+0xaa>
801038b2:	83 7e 24 00          	cmpl   $0x0,0x24(%esi)
801038b6:	74 17                	je     801038cf <wait+0xc1>
      release(&ptable.lock);
801038b8:	83 ec 0c             	sub    $0xc,%esp
801038bb:	68 40 1d 11 80       	push   $0x80111d40
801038c0:	e8 20 04 00 00       	call   80103ce5 <release>
      return -1;
801038c5:	83 c4 10             	add    $0x10,%esp
801038c8:	be ff ff ff ff       	mov    $0xffffffff,%esi
801038cd:	eb b6                	jmp    80103885 <wait+0x77>
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
801038cf:	83 ec 08             	sub    $0x8,%esp
801038d2:	68 40 1d 11 80       	push   $0x80111d40
801038d7:	56                   	push   %esi
801038d8:	e8 a0 fe ff ff       	call   8010377d <sleep>
    havekids = 0;
801038dd:	83 c4 10             	add    $0x10,%esp
801038e0:	e9 45 ff ff ff       	jmp    8010382a <wait+0x1c>

801038e5 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
801038e5:	55                   	push   %ebp
801038e6:	89 e5                	mov    %esp,%ebp
801038e8:	83 ec 14             	sub    $0x14,%esp
  acquire(&ptable.lock);
801038eb:	68 40 1d 11 80       	push   $0x80111d40
801038f0:	e8 8b 03 00 00       	call   80103c80 <acquire>
  wakeup1(chan);
801038f5:	8b 45 08             	mov    0x8(%ebp),%eax
801038f8:	e8 ff f6 ff ff       	call   80102ffc <wakeup1>
  release(&ptable.lock);
801038fd:	c7 04 24 40 1d 11 80 	movl   $0x80111d40,(%esp)
80103904:	e8 dc 03 00 00       	call   80103ce5 <release>
}
80103909:	83 c4 10             	add    $0x10,%esp
8010390c:	c9                   	leave  
8010390d:	c3                   	ret    

8010390e <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
8010390e:	55                   	push   %ebp
8010390f:	89 e5                	mov    %esp,%ebp
80103911:	53                   	push   %ebx
80103912:	83 ec 10             	sub    $0x10,%esp
80103915:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *p;

  acquire(&ptable.lock);
80103918:	68 40 1d 11 80       	push   $0x80111d40
8010391d:	e8 5e 03 00 00       	call   80103c80 <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103922:	83 c4 10             	add    $0x10,%esp
80103925:	b8 74 1d 11 80       	mov    $0x80111d74,%eax
8010392a:	eb 0e                	jmp    8010393a <kill+0x2c>
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
8010392c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
80103933:	eb 1e                	jmp    80103953 <kill+0x45>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80103935:	05 84 00 00 00       	add    $0x84,%eax
8010393a:	3d 74 3e 11 80       	cmp    $0x80113e74,%eax
8010393f:	73 2c                	jae    8010396d <kill+0x5f>
    if(p->pid == pid){
80103941:	39 58 10             	cmp    %ebx,0x10(%eax)
80103944:	75 ef                	jne    80103935 <kill+0x27>
      p->killed = 1;
80103946:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      if(p->state == SLEEPING)
8010394d:	83 78 0c 02          	cmpl   $0x2,0xc(%eax)
80103951:	74 d9                	je     8010392c <kill+0x1e>
      release(&ptable.lock);
80103953:	83 ec 0c             	sub    $0xc,%esp
80103956:	68 40 1d 11 80       	push   $0x80111d40
8010395b:	e8 85 03 00 00       	call   80103ce5 <release>
      return 0;
80103960:	83 c4 10             	add    $0x10,%esp
80103963:	b8 00 00 00 00       	mov    $0x0,%eax
    }
  }
  release(&ptable.lock);
  return -1;
}
80103968:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010396b:	c9                   	leave  
8010396c:	c3                   	ret    
  release(&ptable.lock);
8010396d:	83 ec 0c             	sub    $0xc,%esp
80103970:	68 40 1d 11 80       	push   $0x80111d40
80103975:	e8 6b 03 00 00       	call   80103ce5 <release>
  return -1;
8010397a:	83 c4 10             	add    $0x10,%esp
8010397d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103982:	eb e4                	jmp    80103968 <kill+0x5a>

80103984 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80103984:	55                   	push   %ebp
80103985:	89 e5                	mov    %esp,%ebp
80103987:	56                   	push   %esi
80103988:	53                   	push   %ebx
80103989:	83 ec 30             	sub    $0x30,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010398c:	bb 74 1d 11 80       	mov    $0x80111d74,%ebx
80103991:	eb 36                	jmp    801039c9 <procdump+0x45>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
80103993:	b8 4b 6e 10 80       	mov    $0x80106e4b,%eax
    cprintf("%d %s %s", p->pid, state, p->name);
80103998:	8d 53 6c             	lea    0x6c(%ebx),%edx
8010399b:	52                   	push   %edx
8010399c:	50                   	push   %eax
8010399d:	ff 73 10             	push   0x10(%ebx)
801039a0:	68 4f 6e 10 80       	push   $0x80106e4f
801039a5:	e8 5d cc ff ff       	call   80100607 <cprintf>
    if(p->state == SLEEPING){
801039aa:	83 c4 10             	add    $0x10,%esp
801039ad:	83 7b 0c 02          	cmpl   $0x2,0xc(%ebx)
801039b1:	74 3c                	je     801039ef <procdump+0x6b>
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
801039b3:	83 ec 0c             	sub    $0xc,%esp
801039b6:	68 c7 71 10 80       	push   $0x801071c7
801039bb:	e8 47 cc ff ff       	call   80100607 <cprintf>
801039c0:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801039c3:	81 c3 84 00 00 00    	add    $0x84,%ebx
801039c9:	81 fb 74 3e 11 80    	cmp    $0x80113e74,%ebx
801039cf:	73 61                	jae    80103a32 <procdump+0xae>
    if(p->state == UNUSED)
801039d1:	8b 43 0c             	mov    0xc(%ebx),%eax
801039d4:	85 c0                	test   %eax,%eax
801039d6:	74 eb                	je     801039c3 <procdump+0x3f>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801039d8:	83 f8 05             	cmp    $0x5,%eax
801039db:	77 b6                	ja     80103993 <procdump+0xf>
801039dd:	8b 04 85 ac 6e 10 80 	mov    -0x7fef9154(,%eax,4),%eax
801039e4:	85 c0                	test   %eax,%eax
801039e6:	75 b0                	jne    80103998 <procdump+0x14>
      state = "???";
801039e8:	b8 4b 6e 10 80       	mov    $0x80106e4b,%eax
801039ed:	eb a9                	jmp    80103998 <procdump+0x14>
      getcallerpcs((uint*)p->context->ebp+2, pc);
801039ef:	8b 43 1c             	mov    0x1c(%ebx),%eax
801039f2:	8b 40 0c             	mov    0xc(%eax),%eax
801039f5:	83 c0 08             	add    $0x8,%eax
801039f8:	83 ec 08             	sub    $0x8,%esp
801039fb:	8d 55 d0             	lea    -0x30(%ebp),%edx
801039fe:	52                   	push   %edx
801039ff:	50                   	push   %eax
80103a00:	e8 5a 01 00 00       	call   80103b5f <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a05:	83 c4 10             	add    $0x10,%esp
80103a08:	be 00 00 00 00       	mov    $0x0,%esi
80103a0d:	eb 14                	jmp    80103a23 <procdump+0x9f>
        cprintf(" %p", pc[i]);
80103a0f:	83 ec 08             	sub    $0x8,%esp
80103a12:	50                   	push   %eax
80103a13:	68 a1 68 10 80       	push   $0x801068a1
80103a18:	e8 ea cb ff ff       	call   80100607 <cprintf>
      for(i=0; i<10 && pc[i] != 0; i++)
80103a1d:	83 c6 01             	add    $0x1,%esi
80103a20:	83 c4 10             	add    $0x10,%esp
80103a23:	83 fe 09             	cmp    $0x9,%esi
80103a26:	7f 8b                	jg     801039b3 <procdump+0x2f>
80103a28:	8b 44 b5 d0          	mov    -0x30(%ebp,%esi,4),%eax
80103a2c:	85 c0                	test   %eax,%eax
80103a2e:	75 df                	jne    80103a0f <procdump+0x8b>
80103a30:	eb 81                	jmp    801039b3 <procdump+0x2f>
  }
}
80103a32:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103a35:	5b                   	pop    %ebx
80103a36:	5e                   	pop    %esi
80103a37:	5d                   	pop    %ebp
80103a38:	c3                   	ret    

80103a39 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80103a39:	55                   	push   %ebp
80103a3a:	89 e5                	mov    %esp,%ebp
80103a3c:	53                   	push   %ebx
80103a3d:	83 ec 0c             	sub    $0xc,%esp
80103a40:	8b 5d 08             	mov    0x8(%ebp),%ebx
  initlock(&lk->lk, "sleep lock");
80103a43:	68 c4 6e 10 80       	push   $0x80106ec4
80103a48:	8d 43 04             	lea    0x4(%ebx),%eax
80103a4b:	50                   	push   %eax
80103a4c:	e8 f3 00 00 00       	call   80103b44 <initlock>
  lk->name = name;
80103a51:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a54:	89 43 38             	mov    %eax,0x38(%ebx)
  lk->locked = 0;
80103a57:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103a5d:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
}
80103a64:	83 c4 10             	add    $0x10,%esp
80103a67:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103a6a:	c9                   	leave  
80103a6b:	c3                   	ret    

80103a6c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80103a6c:	55                   	push   %ebp
80103a6d:	89 e5                	mov    %esp,%ebp
80103a6f:	56                   	push   %esi
80103a70:	53                   	push   %ebx
80103a71:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103a74:	8d 73 04             	lea    0x4(%ebx),%esi
80103a77:	83 ec 0c             	sub    $0xc,%esp
80103a7a:	56                   	push   %esi
80103a7b:	e8 00 02 00 00       	call   80103c80 <acquire>
  while (lk->locked) {
80103a80:	83 c4 10             	add    $0x10,%esp
80103a83:	eb 0d                	jmp    80103a92 <acquiresleep+0x26>
    sleep(lk, &lk->lk);
80103a85:	83 ec 08             	sub    $0x8,%esp
80103a88:	56                   	push   %esi
80103a89:	53                   	push   %ebx
80103a8a:	e8 ee fc ff ff       	call   8010377d <sleep>
80103a8f:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80103a92:	83 3b 00             	cmpl   $0x0,(%ebx)
80103a95:	75 ee                	jne    80103a85 <acquiresleep+0x19>
  }
  lk->locked = 1;
80103a97:	c7 03 01 00 00 00    	movl   $0x1,(%ebx)
  lk->pid = myproc()->pid;
80103a9d:	e8 79 f7 ff ff       	call   8010321b <myproc>
80103aa2:	8b 40 10             	mov    0x10(%eax),%eax
80103aa5:	89 43 3c             	mov    %eax,0x3c(%ebx)
  release(&lk->lk);
80103aa8:	83 ec 0c             	sub    $0xc,%esp
80103aab:	56                   	push   %esi
80103aac:	e8 34 02 00 00       	call   80103ce5 <release>
}
80103ab1:	83 c4 10             	add    $0x10,%esp
80103ab4:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103ab7:	5b                   	pop    %ebx
80103ab8:	5e                   	pop    %esi
80103ab9:	5d                   	pop    %ebp
80103aba:	c3                   	ret    

80103abb <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80103abb:	55                   	push   %ebp
80103abc:	89 e5                	mov    %esp,%ebp
80103abe:	56                   	push   %esi
80103abf:	53                   	push   %ebx
80103ac0:	8b 5d 08             	mov    0x8(%ebp),%ebx
  acquire(&lk->lk);
80103ac3:	8d 73 04             	lea    0x4(%ebx),%esi
80103ac6:	83 ec 0c             	sub    $0xc,%esp
80103ac9:	56                   	push   %esi
80103aca:	e8 b1 01 00 00       	call   80103c80 <acquire>
  lk->locked = 0;
80103acf:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  lk->pid = 0;
80103ad5:	c7 43 3c 00 00 00 00 	movl   $0x0,0x3c(%ebx)
  wakeup(lk);
80103adc:	89 1c 24             	mov    %ebx,(%esp)
80103adf:	e8 01 fe ff ff       	call   801038e5 <wakeup>
  release(&lk->lk);
80103ae4:	89 34 24             	mov    %esi,(%esp)
80103ae7:	e8 f9 01 00 00       	call   80103ce5 <release>
}
80103aec:	83 c4 10             	add    $0x10,%esp
80103aef:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103af2:	5b                   	pop    %ebx
80103af3:	5e                   	pop    %esi
80103af4:	5d                   	pop    %ebp
80103af5:	c3                   	ret    

80103af6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80103af6:	55                   	push   %ebp
80103af7:	89 e5                	mov    %esp,%ebp
80103af9:	56                   	push   %esi
80103afa:	53                   	push   %ebx
80103afb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  int r;
  
  acquire(&lk->lk);
80103afe:	8d 73 04             	lea    0x4(%ebx),%esi
80103b01:	83 ec 0c             	sub    $0xc,%esp
80103b04:	56                   	push   %esi
80103b05:	e8 76 01 00 00       	call   80103c80 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
80103b0a:	83 c4 10             	add    $0x10,%esp
80103b0d:	83 3b 00             	cmpl   $0x0,(%ebx)
80103b10:	75 17                	jne    80103b29 <holdingsleep+0x33>
80103b12:	bb 00 00 00 00       	mov    $0x0,%ebx
  release(&lk->lk);
80103b17:	83 ec 0c             	sub    $0xc,%esp
80103b1a:	56                   	push   %esi
80103b1b:	e8 c5 01 00 00       	call   80103ce5 <release>
  return r;
}
80103b20:	89 d8                	mov    %ebx,%eax
80103b22:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103b25:	5b                   	pop    %ebx
80103b26:	5e                   	pop    %esi
80103b27:	5d                   	pop    %ebp
80103b28:	c3                   	ret    
  r = lk->locked && (lk->pid == myproc()->pid);
80103b29:	8b 5b 3c             	mov    0x3c(%ebx),%ebx
80103b2c:	e8 ea f6 ff ff       	call   8010321b <myproc>
80103b31:	3b 58 10             	cmp    0x10(%eax),%ebx
80103b34:	74 07                	je     80103b3d <holdingsleep+0x47>
80103b36:	bb 00 00 00 00       	mov    $0x0,%ebx
80103b3b:	eb da                	jmp    80103b17 <holdingsleep+0x21>
80103b3d:	bb 01 00 00 00       	mov    $0x1,%ebx
80103b42:	eb d3                	jmp    80103b17 <holdingsleep+0x21>

80103b44 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80103b44:	55                   	push   %ebp
80103b45:	89 e5                	mov    %esp,%ebp
80103b47:	8b 45 08             	mov    0x8(%ebp),%eax
  lk->name = name;
80103b4a:	8b 55 0c             	mov    0xc(%ebp),%edx
80103b4d:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80103b50:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80103b56:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80103b5d:	5d                   	pop    %ebp
80103b5e:	c3                   	ret    

80103b5f <getcallerpcs>:
}

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80103b5f:	55                   	push   %ebp
80103b60:	89 e5                	mov    %esp,%ebp
80103b62:	53                   	push   %ebx
80103b63:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
80103b66:	8b 45 08             	mov    0x8(%ebp),%eax
80103b69:	8d 50 f8             	lea    -0x8(%eax),%edx
  for(i = 0; i < 10; i++){
80103b6c:	b8 00 00 00 00       	mov    $0x0,%eax
80103b71:	83 f8 09             	cmp    $0x9,%eax
80103b74:	7f 25                	jg     80103b9b <getcallerpcs+0x3c>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80103b76:	8d 9a 00 00 00 80    	lea    -0x80000000(%edx),%ebx
80103b7c:	81 fb fe ff ff 7f    	cmp    $0x7ffffffe,%ebx
80103b82:	77 17                	ja     80103b9b <getcallerpcs+0x3c>
      break;
    pcs[i] = ebp[1];     // saved %eip
80103b84:	8b 5a 04             	mov    0x4(%edx),%ebx
80103b87:	89 1c 81             	mov    %ebx,(%ecx,%eax,4)
    ebp = (uint*)ebp[0]; // saved %ebp
80103b8a:	8b 12                	mov    (%edx),%edx
  for(i = 0; i < 10; i++){
80103b8c:	83 c0 01             	add    $0x1,%eax
80103b8f:	eb e0                	jmp    80103b71 <getcallerpcs+0x12>
  }
  for(; i < 10; i++)
    pcs[i] = 0;
80103b91:	c7 04 81 00 00 00 00 	movl   $0x0,(%ecx,%eax,4)
  for(; i < 10; i++)
80103b98:	83 c0 01             	add    $0x1,%eax
80103b9b:	83 f8 09             	cmp    $0x9,%eax
80103b9e:	7e f1                	jle    80103b91 <getcallerpcs+0x32>
}
80103ba0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103ba3:	c9                   	leave  
80103ba4:	c3                   	ret    

80103ba5 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80103ba5:	55                   	push   %ebp
80103ba6:	89 e5                	mov    %esp,%ebp
80103ba8:	53                   	push   %ebx
80103ba9:	83 ec 04             	sub    $0x4,%esp
80103bac:	9c                   	pushf  
80103bad:	5b                   	pop    %ebx
  asm volatile("cli");
80103bae:	fa                   	cli    
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
80103baf:	e8 f0 f5 ff ff       	call   801031a4 <mycpu>
80103bb4:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103bbb:	74 11                	je     80103bce <pushcli+0x29>
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
80103bbd:	e8 e2 f5 ff ff       	call   801031a4 <mycpu>
80103bc2:	83 80 a4 00 00 00 01 	addl   $0x1,0xa4(%eax)
}
80103bc9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103bcc:	c9                   	leave  
80103bcd:	c3                   	ret    
    mycpu()->intena = eflags & FL_IF;
80103bce:	e8 d1 f5 ff ff       	call   801031a4 <mycpu>
80103bd3:	81 e3 00 02 00 00    	and    $0x200,%ebx
80103bd9:	89 98 a8 00 00 00    	mov    %ebx,0xa8(%eax)
80103bdf:	eb dc                	jmp    80103bbd <pushcli+0x18>

80103be1 <popcli>:

void
popcli(void)
{
80103be1:	55                   	push   %ebp
80103be2:	89 e5                	mov    %esp,%ebp
80103be4:	83 ec 08             	sub    $0x8,%esp
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103be7:	9c                   	pushf  
80103be8:	58                   	pop    %eax
  if(readeflags()&FL_IF)
80103be9:	f6 c4 02             	test   $0x2,%ah
80103bec:	75 28                	jne    80103c16 <popcli+0x35>
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
80103bee:	e8 b1 f5 ff ff       	call   801031a4 <mycpu>
80103bf3:	8b 88 a4 00 00 00    	mov    0xa4(%eax),%ecx
80103bf9:	8d 51 ff             	lea    -0x1(%ecx),%edx
80103bfc:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80103c02:	85 d2                	test   %edx,%edx
80103c04:	78 1d                	js     80103c23 <popcli+0x42>
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c06:	e8 99 f5 ff ff       	call   801031a4 <mycpu>
80103c0b:	83 b8 a4 00 00 00 00 	cmpl   $0x0,0xa4(%eax)
80103c12:	74 1c                	je     80103c30 <popcli+0x4f>
    sti();
}
80103c14:	c9                   	leave  
80103c15:	c3                   	ret    
    panic("popcli - interruptible");
80103c16:	83 ec 0c             	sub    $0xc,%esp
80103c19:	68 cf 6e 10 80       	push   $0x80106ecf
80103c1e:	e8 25 c7 ff ff       	call   80100348 <panic>
    panic("popcli");
80103c23:	83 ec 0c             	sub    $0xc,%esp
80103c26:	68 e6 6e 10 80       	push   $0x80106ee6
80103c2b:	e8 18 c7 ff ff       	call   80100348 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
80103c30:	e8 6f f5 ff ff       	call   801031a4 <mycpu>
80103c35:	83 b8 a8 00 00 00 00 	cmpl   $0x0,0xa8(%eax)
80103c3c:	74 d6                	je     80103c14 <popcli+0x33>
  asm volatile("sti");
80103c3e:	fb                   	sti    
}
80103c3f:	eb d3                	jmp    80103c14 <popcli+0x33>

80103c41 <holding>:
{
80103c41:	55                   	push   %ebp
80103c42:	89 e5                	mov    %esp,%ebp
80103c44:	53                   	push   %ebx
80103c45:	83 ec 04             	sub    $0x4,%esp
80103c48:	8b 5d 08             	mov    0x8(%ebp),%ebx
  pushcli();
80103c4b:	e8 55 ff ff ff       	call   80103ba5 <pushcli>
  r = lock->locked && lock->cpu == mycpu();
80103c50:	83 3b 00             	cmpl   $0x0,(%ebx)
80103c53:	75 11                	jne    80103c66 <holding+0x25>
80103c55:	bb 00 00 00 00       	mov    $0x0,%ebx
  popcli();
80103c5a:	e8 82 ff ff ff       	call   80103be1 <popcli>
}
80103c5f:	89 d8                	mov    %ebx,%eax
80103c61:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103c64:	c9                   	leave  
80103c65:	c3                   	ret    
  r = lock->locked && lock->cpu == mycpu();
80103c66:	8b 5b 08             	mov    0x8(%ebx),%ebx
80103c69:	e8 36 f5 ff ff       	call   801031a4 <mycpu>
80103c6e:	39 c3                	cmp    %eax,%ebx
80103c70:	74 07                	je     80103c79 <holding+0x38>
80103c72:	bb 00 00 00 00       	mov    $0x0,%ebx
80103c77:	eb e1                	jmp    80103c5a <holding+0x19>
80103c79:	bb 01 00 00 00       	mov    $0x1,%ebx
80103c7e:	eb da                	jmp    80103c5a <holding+0x19>

80103c80 <acquire>:
{
80103c80:	55                   	push   %ebp
80103c81:	89 e5                	mov    %esp,%ebp
80103c83:	53                   	push   %ebx
80103c84:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80103c87:	e8 19 ff ff ff       	call   80103ba5 <pushcli>
  if(holding(lk))
80103c8c:	83 ec 0c             	sub    $0xc,%esp
80103c8f:	ff 75 08             	push   0x8(%ebp)
80103c92:	e8 aa ff ff ff       	call   80103c41 <holding>
80103c97:	83 c4 10             	add    $0x10,%esp
80103c9a:	85 c0                	test   %eax,%eax
80103c9c:	75 3a                	jne    80103cd8 <acquire+0x58>
  while(xchg(&lk->locked, 1) != 0)
80103c9e:	8b 55 08             	mov    0x8(%ebp),%edx
  asm volatile("lock; xchgl %0, %1" :
80103ca1:	b8 01 00 00 00       	mov    $0x1,%eax
80103ca6:	f0 87 02             	lock xchg %eax,(%edx)
80103ca9:	85 c0                	test   %eax,%eax
80103cab:	75 f1                	jne    80103c9e <acquire+0x1e>
  __sync_synchronize();
80103cad:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  lk->cpu = mycpu();
80103cb2:	8b 5d 08             	mov    0x8(%ebp),%ebx
80103cb5:	e8 ea f4 ff ff       	call   801031a4 <mycpu>
80103cba:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80103cbd:	8b 45 08             	mov    0x8(%ebp),%eax
80103cc0:	83 c0 0c             	add    $0xc,%eax
80103cc3:	83 ec 08             	sub    $0x8,%esp
80103cc6:	50                   	push   %eax
80103cc7:	8d 45 08             	lea    0x8(%ebp),%eax
80103cca:	50                   	push   %eax
80103ccb:	e8 8f fe ff ff       	call   80103b5f <getcallerpcs>
}
80103cd0:	83 c4 10             	add    $0x10,%esp
80103cd3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103cd6:	c9                   	leave  
80103cd7:	c3                   	ret    
    panic("acquire");
80103cd8:	83 ec 0c             	sub    $0xc,%esp
80103cdb:	68 ed 6e 10 80       	push   $0x80106eed
80103ce0:	e8 63 c6 ff ff       	call   80100348 <panic>

80103ce5 <release>:
{
80103ce5:	55                   	push   %ebp
80103ce6:	89 e5                	mov    %esp,%ebp
80103ce8:	53                   	push   %ebx
80103ce9:	83 ec 10             	sub    $0x10,%esp
80103cec:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(!holding(lk))
80103cef:	53                   	push   %ebx
80103cf0:	e8 4c ff ff ff       	call   80103c41 <holding>
80103cf5:	83 c4 10             	add    $0x10,%esp
80103cf8:	85 c0                	test   %eax,%eax
80103cfa:	74 23                	je     80103d1f <release+0x3a>
  lk->pcs[0] = 0;
80103cfc:	c7 43 0c 00 00 00 00 	movl   $0x0,0xc(%ebx)
  lk->cpu = 0;
80103d03:	c7 43 08 00 00 00 00 	movl   $0x0,0x8(%ebx)
  __sync_synchronize();
80103d0a:	f0 83 0c 24 00       	lock orl $0x0,(%esp)
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80103d0f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  popcli();
80103d15:	e8 c7 fe ff ff       	call   80103be1 <popcli>
}
80103d1a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103d1d:	c9                   	leave  
80103d1e:	c3                   	ret    
    panic("release");
80103d1f:	83 ec 0c             	sub    $0xc,%esp
80103d22:	68 f5 6e 10 80       	push   $0x80106ef5
80103d27:	e8 1c c6 ff ff       	call   80100348 <panic>

80103d2c <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80103d2c:	55                   	push   %ebp
80103d2d:	89 e5                	mov    %esp,%ebp
80103d2f:	57                   	push   %edi
80103d30:	53                   	push   %ebx
80103d31:	8b 55 08             	mov    0x8(%ebp),%edx
80103d34:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d37:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
80103d3a:	f6 c2 03             	test   $0x3,%dl
80103d3d:	75 25                	jne    80103d64 <memset+0x38>
80103d3f:	f6 c1 03             	test   $0x3,%cl
80103d42:	75 20                	jne    80103d64 <memset+0x38>
    c &= 0xFF;
80103d44:	0f b6 f8             	movzbl %al,%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80103d47:	c1 e9 02             	shr    $0x2,%ecx
80103d4a:	c1 e0 18             	shl    $0x18,%eax
80103d4d:	89 fb                	mov    %edi,%ebx
80103d4f:	c1 e3 10             	shl    $0x10,%ebx
80103d52:	09 d8                	or     %ebx,%eax
80103d54:	89 fb                	mov    %edi,%ebx
80103d56:	c1 e3 08             	shl    $0x8,%ebx
80103d59:	09 d8                	or     %ebx,%eax
80103d5b:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
80103d5d:	89 d7                	mov    %edx,%edi
80103d5f:	fc                   	cld    
80103d60:	f3 ab                	rep stos %eax,%es:(%edi)
}
80103d62:	eb 05                	jmp    80103d69 <memset+0x3d>
  asm volatile("cld; rep stosb" :
80103d64:	89 d7                	mov    %edx,%edi
80103d66:	fc                   	cld    
80103d67:	f3 aa                	rep stos %al,%es:(%edi)
  } else
    stosb(dst, c, n);
  return dst;
}
80103d69:	89 d0                	mov    %edx,%eax
80103d6b:	5b                   	pop    %ebx
80103d6c:	5f                   	pop    %edi
80103d6d:	5d                   	pop    %ebp
80103d6e:	c3                   	ret    

80103d6f <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80103d6f:	55                   	push   %ebp
80103d70:	89 e5                	mov    %esp,%ebp
80103d72:	56                   	push   %esi
80103d73:	53                   	push   %ebx
80103d74:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103d77:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d7a:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80103d7d:	eb 08                	jmp    80103d87 <memcmp+0x18>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
80103d7f:	83 c1 01             	add    $0x1,%ecx
80103d82:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80103d85:	89 f0                	mov    %esi,%eax
80103d87:	8d 70 ff             	lea    -0x1(%eax),%esi
80103d8a:	85 c0                	test   %eax,%eax
80103d8c:	74 12                	je     80103da0 <memcmp+0x31>
    if(*s1 != *s2)
80103d8e:	0f b6 01             	movzbl (%ecx),%eax
80103d91:	0f b6 1a             	movzbl (%edx),%ebx
80103d94:	38 d8                	cmp    %bl,%al
80103d96:	74 e7                	je     80103d7f <memcmp+0x10>
      return *s1 - *s2;
80103d98:	0f b6 c0             	movzbl %al,%eax
80103d9b:	0f b6 db             	movzbl %bl,%ebx
80103d9e:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80103da0:	5b                   	pop    %ebx
80103da1:	5e                   	pop    %esi
80103da2:	5d                   	pop    %ebp
80103da3:	c3                   	ret    

80103da4 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80103da4:	55                   	push   %ebp
80103da5:	89 e5                	mov    %esp,%ebp
80103da7:	56                   	push   %esi
80103da8:	53                   	push   %ebx
80103da9:	8b 75 08             	mov    0x8(%ebp),%esi
80103dac:	8b 55 0c             	mov    0xc(%ebp),%edx
80103daf:	8b 45 10             	mov    0x10(%ebp),%eax
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80103db2:	39 f2                	cmp    %esi,%edx
80103db4:	73 3c                	jae    80103df2 <memmove+0x4e>
80103db6:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80103db9:	39 f1                	cmp    %esi,%ecx
80103dbb:	76 39                	jbe    80103df6 <memmove+0x52>
    s += n;
    d += n;
80103dbd:	8d 14 06             	lea    (%esi,%eax,1),%edx
    while(n-- > 0)
80103dc0:	eb 0d                	jmp    80103dcf <memmove+0x2b>
      *--d = *--s;
80103dc2:	83 e9 01             	sub    $0x1,%ecx
80103dc5:	83 ea 01             	sub    $0x1,%edx
80103dc8:	0f b6 01             	movzbl (%ecx),%eax
80103dcb:	88 02                	mov    %al,(%edx)
    while(n-- > 0)
80103dcd:	89 d8                	mov    %ebx,%eax
80103dcf:	8d 58 ff             	lea    -0x1(%eax),%ebx
80103dd2:	85 c0                	test   %eax,%eax
80103dd4:	75 ec                	jne    80103dc2 <memmove+0x1e>
80103dd6:	eb 14                	jmp    80103dec <memmove+0x48>
  } else
    while(n-- > 0)
      *d++ = *s++;
80103dd8:	0f b6 02             	movzbl (%edx),%eax
80103ddb:	88 01                	mov    %al,(%ecx)
80103ddd:	8d 49 01             	lea    0x1(%ecx),%ecx
80103de0:	8d 52 01             	lea    0x1(%edx),%edx
    while(n-- > 0)
80103de3:	89 d8                	mov    %ebx,%eax
80103de5:	8d 58 ff             	lea    -0x1(%eax),%ebx
80103de8:	85 c0                	test   %eax,%eax
80103dea:	75 ec                	jne    80103dd8 <memmove+0x34>

  return dst;
}
80103dec:	89 f0                	mov    %esi,%eax
80103dee:	5b                   	pop    %ebx
80103def:	5e                   	pop    %esi
80103df0:	5d                   	pop    %ebp
80103df1:	c3                   	ret    
80103df2:	89 f1                	mov    %esi,%ecx
80103df4:	eb ef                	jmp    80103de5 <memmove+0x41>
80103df6:	89 f1                	mov    %esi,%ecx
80103df8:	eb eb                	jmp    80103de5 <memmove+0x41>

80103dfa <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80103dfa:	55                   	push   %ebp
80103dfb:	89 e5                	mov    %esp,%ebp
80103dfd:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80103e00:	ff 75 10             	push   0x10(%ebp)
80103e03:	ff 75 0c             	push   0xc(%ebp)
80103e06:	ff 75 08             	push   0x8(%ebp)
80103e09:	e8 96 ff ff ff       	call   80103da4 <memmove>
}
80103e0e:	c9                   	leave  
80103e0f:	c3                   	ret    

80103e10 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80103e10:	55                   	push   %ebp
80103e11:	89 e5                	mov    %esp,%ebp
80103e13:	53                   	push   %ebx
80103e14:	8b 55 08             	mov    0x8(%ebp),%edx
80103e17:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e1a:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80103e1d:	eb 09                	jmp    80103e28 <strncmp+0x18>
    n--, p++, q++;
80103e1f:	83 e8 01             	sub    $0x1,%eax
80103e22:	83 c2 01             	add    $0x1,%edx
80103e25:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
80103e28:	85 c0                	test   %eax,%eax
80103e2a:	74 0b                	je     80103e37 <strncmp+0x27>
80103e2c:	0f b6 1a             	movzbl (%edx),%ebx
80103e2f:	84 db                	test   %bl,%bl
80103e31:	74 04                	je     80103e37 <strncmp+0x27>
80103e33:	3a 19                	cmp    (%ecx),%bl
80103e35:	74 e8                	je     80103e1f <strncmp+0xf>
  if(n == 0)
80103e37:	85 c0                	test   %eax,%eax
80103e39:	74 0d                	je     80103e48 <strncmp+0x38>
    return 0;
  return (uchar)*p - (uchar)*q;
80103e3b:	0f b6 02             	movzbl (%edx),%eax
80103e3e:	0f b6 11             	movzbl (%ecx),%edx
80103e41:	29 d0                	sub    %edx,%eax
}
80103e43:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103e46:	c9                   	leave  
80103e47:	c3                   	ret    
    return 0;
80103e48:	b8 00 00 00 00       	mov    $0x0,%eax
80103e4d:	eb f4                	jmp    80103e43 <strncmp+0x33>

80103e4f <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80103e4f:	55                   	push   %ebp
80103e50:	89 e5                	mov    %esp,%ebp
80103e52:	57                   	push   %edi
80103e53:	56                   	push   %esi
80103e54:	53                   	push   %ebx
80103e55:	8b 7d 08             	mov    0x8(%ebp),%edi
80103e58:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103e5b:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80103e5e:	89 fa                	mov    %edi,%edx
80103e60:	eb 04                	jmp    80103e66 <strncpy+0x17>
80103e62:	89 f1                	mov    %esi,%ecx
80103e64:	89 da                	mov    %ebx,%edx
80103e66:	89 c3                	mov    %eax,%ebx
80103e68:	83 e8 01             	sub    $0x1,%eax
80103e6b:	85 db                	test   %ebx,%ebx
80103e6d:	7e 11                	jle    80103e80 <strncpy+0x31>
80103e6f:	8d 71 01             	lea    0x1(%ecx),%esi
80103e72:	8d 5a 01             	lea    0x1(%edx),%ebx
80103e75:	0f b6 09             	movzbl (%ecx),%ecx
80103e78:	88 0a                	mov    %cl,(%edx)
80103e7a:	84 c9                	test   %cl,%cl
80103e7c:	75 e4                	jne    80103e62 <strncpy+0x13>
80103e7e:	89 da                	mov    %ebx,%edx
    ;
  while(n-- > 0)
80103e80:	8d 48 ff             	lea    -0x1(%eax),%ecx
80103e83:	85 c0                	test   %eax,%eax
80103e85:	7e 0a                	jle    80103e91 <strncpy+0x42>
    *s++ = 0;
80103e87:	c6 02 00             	movb   $0x0,(%edx)
  while(n-- > 0)
80103e8a:	89 c8                	mov    %ecx,%eax
    *s++ = 0;
80103e8c:	8d 52 01             	lea    0x1(%edx),%edx
80103e8f:	eb ef                	jmp    80103e80 <strncpy+0x31>
  return os;
}
80103e91:	89 f8                	mov    %edi,%eax
80103e93:	5b                   	pop    %ebx
80103e94:	5e                   	pop    %esi
80103e95:	5f                   	pop    %edi
80103e96:	5d                   	pop    %ebp
80103e97:	c3                   	ret    

80103e98 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80103e98:	55                   	push   %ebp
80103e99:	89 e5                	mov    %esp,%ebp
80103e9b:	57                   	push   %edi
80103e9c:	56                   	push   %esi
80103e9d:	53                   	push   %ebx
80103e9e:	8b 7d 08             	mov    0x8(%ebp),%edi
80103ea1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80103ea4:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  if(n <= 0)
80103ea7:	85 c0                	test   %eax,%eax
80103ea9:	7e 23                	jle    80103ece <safestrcpy+0x36>
80103eab:	89 fa                	mov    %edi,%edx
80103ead:	eb 04                	jmp    80103eb3 <safestrcpy+0x1b>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80103eaf:	89 f1                	mov    %esi,%ecx
80103eb1:	89 da                	mov    %ebx,%edx
80103eb3:	83 e8 01             	sub    $0x1,%eax
80103eb6:	85 c0                	test   %eax,%eax
80103eb8:	7e 11                	jle    80103ecb <safestrcpy+0x33>
80103eba:	8d 71 01             	lea    0x1(%ecx),%esi
80103ebd:	8d 5a 01             	lea    0x1(%edx),%ebx
80103ec0:	0f b6 09             	movzbl (%ecx),%ecx
80103ec3:	88 0a                	mov    %cl,(%edx)
80103ec5:	84 c9                	test   %cl,%cl
80103ec7:	75 e6                	jne    80103eaf <safestrcpy+0x17>
80103ec9:	89 da                	mov    %ebx,%edx
    ;
  *s = 0;
80103ecb:	c6 02 00             	movb   $0x0,(%edx)
  return os;
}
80103ece:	89 f8                	mov    %edi,%eax
80103ed0:	5b                   	pop    %ebx
80103ed1:	5e                   	pop    %esi
80103ed2:	5f                   	pop    %edi
80103ed3:	5d                   	pop    %ebp
80103ed4:	c3                   	ret    

80103ed5 <strlen>:

int
strlen(const char *s)
{
80103ed5:	55                   	push   %ebp
80103ed6:	89 e5                	mov    %esp,%ebp
80103ed8:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80103edb:	b8 00 00 00 00       	mov    $0x0,%eax
80103ee0:	eb 03                	jmp    80103ee5 <strlen+0x10>
80103ee2:	83 c0 01             	add    $0x1,%eax
80103ee5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80103ee9:	75 f7                	jne    80103ee2 <strlen+0xd>
    ;
  return n;
}
80103eeb:	5d                   	pop    %ebp
80103eec:	c3                   	ret    

80103eed <swtch>:
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax
80103eed:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80103ef1:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-saved registers
  pushl %ebp
80103ef5:	55                   	push   %ebp
  pushl %ebx
80103ef6:	53                   	push   %ebx
  pushl %esi
80103ef7:	56                   	push   %esi
  pushl %edi
80103ef8:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80103ef9:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80103efb:	89 d4                	mov    %edx,%esp

  # Load new callee-saved registers
  popl %edi
80103efd:	5f                   	pop    %edi
  popl %esi
80103efe:	5e                   	pop    %esi
  popl %ebx
80103eff:	5b                   	pop    %ebx
  popl %ebp
80103f00:	5d                   	pop    %ebp
  ret
80103f01:	c3                   	ret    

80103f02 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80103f02:	55                   	push   %ebp
80103f03:	89 e5                	mov    %esp,%ebp
80103f05:	53                   	push   %ebx
80103f06:	83 ec 04             	sub    $0x4,%esp
80103f09:	8b 5d 08             	mov    0x8(%ebp),%ebx
  struct proc *curproc = myproc();
80103f0c:	e8 0a f3 ff ff       	call   8010321b <myproc>

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80103f11:	8b 00                	mov    (%eax),%eax
80103f13:	39 d8                	cmp    %ebx,%eax
80103f15:	76 18                	jbe    80103f2f <fetchint+0x2d>
80103f17:	8d 53 04             	lea    0x4(%ebx),%edx
80103f1a:	39 d0                	cmp    %edx,%eax
80103f1c:	72 18                	jb     80103f36 <fetchint+0x34>
    return -1;
  *ip = *(int*)(addr);
80103f1e:	8b 13                	mov    (%ebx),%edx
80103f20:	8b 45 0c             	mov    0xc(%ebp),%eax
80103f23:	89 10                	mov    %edx,(%eax)
  return 0;
80103f25:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103f2a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f2d:	c9                   	leave  
80103f2e:	c3                   	ret    
    return -1;
80103f2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f34:	eb f4                	jmp    80103f2a <fetchint+0x28>
80103f36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f3b:	eb ed                	jmp    80103f2a <fetchint+0x28>

80103f3d <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80103f3d:	55                   	push   %ebp
80103f3e:	89 e5                	mov    %esp,%ebp
80103f40:	53                   	push   %ebx
80103f41:	83 ec 04             	sub    $0x4,%esp
80103f44:	8b 5d 08             	mov    0x8(%ebp),%ebx
  char *s, *ep;
  struct proc *curproc = myproc();
80103f47:	e8 cf f2 ff ff       	call   8010321b <myproc>

  if(addr >= curproc->sz)
80103f4c:	39 18                	cmp    %ebx,(%eax)
80103f4e:	76 25                	jbe    80103f75 <fetchstr+0x38>
    return -1;
  *pp = (char*)addr;
80103f50:	8b 55 0c             	mov    0xc(%ebp),%edx
80103f53:	89 1a                	mov    %ebx,(%edx)
  ep = (char*)curproc->sz;
80103f55:	8b 10                	mov    (%eax),%edx
  for(s = *pp; s < ep; s++){
80103f57:	89 d8                	mov    %ebx,%eax
80103f59:	eb 03                	jmp    80103f5e <fetchstr+0x21>
80103f5b:	83 c0 01             	add    $0x1,%eax
80103f5e:	39 d0                	cmp    %edx,%eax
80103f60:	73 09                	jae    80103f6b <fetchstr+0x2e>
    if(*s == 0)
80103f62:	80 38 00             	cmpb   $0x0,(%eax)
80103f65:	75 f4                	jne    80103f5b <fetchstr+0x1e>
      return s - *pp;
80103f67:	29 d8                	sub    %ebx,%eax
80103f69:	eb 05                	jmp    80103f70 <fetchstr+0x33>
  }
  return -1;
80103f6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f70:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80103f73:	c9                   	leave  
80103f74:	c3                   	ret    
    return -1;
80103f75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f7a:	eb f4                	jmp    80103f70 <fetchstr+0x33>

80103f7c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
80103f7c:	55                   	push   %ebp
80103f7d:	89 e5                	mov    %esp,%ebp
80103f7f:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
80103f82:	e8 94 f2 ff ff       	call   8010321b <myproc>
80103f87:	8b 50 18             	mov    0x18(%eax),%edx
80103f8a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8d:	c1 e0 02             	shl    $0x2,%eax
80103f90:	03 42 44             	add    0x44(%edx),%eax
80103f93:	83 ec 08             	sub    $0x8,%esp
80103f96:	ff 75 0c             	push   0xc(%ebp)
80103f99:	83 c0 04             	add    $0x4,%eax
80103f9c:	50                   	push   %eax
80103f9d:	e8 60 ff ff ff       	call   80103f02 <fetchint>
}
80103fa2:	c9                   	leave  
80103fa3:	c3                   	ret    

80103fa4 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80103fa4:	55                   	push   %ebp
80103fa5:	89 e5                	mov    %esp,%ebp
80103fa7:	56                   	push   %esi
80103fa8:	53                   	push   %ebx
80103fa9:	83 ec 10             	sub    $0x10,%esp
80103fac:	8b 5d 10             	mov    0x10(%ebp),%ebx
  int i;
  struct proc *curproc = myproc();
80103faf:	e8 67 f2 ff ff       	call   8010321b <myproc>
80103fb4:	89 c6                	mov    %eax,%esi
 
  if(argint(n, &i) < 0)
80103fb6:	83 ec 08             	sub    $0x8,%esp
80103fb9:	8d 45 f4             	lea    -0xc(%ebp),%eax
80103fbc:	50                   	push   %eax
80103fbd:	ff 75 08             	push   0x8(%ebp)
80103fc0:	e8 b7 ff ff ff       	call   80103f7c <argint>
80103fc5:	83 c4 10             	add    $0x10,%esp
80103fc8:	85 c0                	test   %eax,%eax
80103fca:	78 24                	js     80103ff0 <argptr+0x4c>
    return -1;
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80103fcc:	85 db                	test   %ebx,%ebx
80103fce:	78 27                	js     80103ff7 <argptr+0x53>
80103fd0:	8b 16                	mov    (%esi),%edx
80103fd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fd5:	39 c2                	cmp    %eax,%edx
80103fd7:	76 25                	jbe    80103ffe <argptr+0x5a>
80103fd9:	01 c3                	add    %eax,%ebx
80103fdb:	39 da                	cmp    %ebx,%edx
80103fdd:	72 26                	jb     80104005 <argptr+0x61>
    return -1;
  *pp = (char*)i;
80103fdf:	8b 55 0c             	mov    0xc(%ebp),%edx
80103fe2:	89 02                	mov    %eax,(%edx)
  return 0;
80103fe4:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103fe9:	8d 65 f8             	lea    -0x8(%ebp),%esp
80103fec:	5b                   	pop    %ebx
80103fed:	5e                   	pop    %esi
80103fee:	5d                   	pop    %ebp
80103fef:	c3                   	ret    
    return -1;
80103ff0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ff5:	eb f2                	jmp    80103fe9 <argptr+0x45>
    return -1;
80103ff7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ffc:	eb eb                	jmp    80103fe9 <argptr+0x45>
80103ffe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104003:	eb e4                	jmp    80103fe9 <argptr+0x45>
80104005:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010400a:	eb dd                	jmp    80103fe9 <argptr+0x45>

8010400c <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010400c:	55                   	push   %ebp
8010400d:	89 e5                	mov    %esp,%ebp
8010400f:	83 ec 20             	sub    $0x20,%esp
  int addr;
  if(argint(n, &addr) < 0)
80104012:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104015:	50                   	push   %eax
80104016:	ff 75 08             	push   0x8(%ebp)
80104019:	e8 5e ff ff ff       	call   80103f7c <argint>
8010401e:	83 c4 10             	add    $0x10,%esp
80104021:	85 c0                	test   %eax,%eax
80104023:	78 13                	js     80104038 <argstr+0x2c>
    return -1;
  return fetchstr(addr, pp);
80104025:	83 ec 08             	sub    $0x8,%esp
80104028:	ff 75 0c             	push   0xc(%ebp)
8010402b:	ff 75 f4             	push   -0xc(%ebp)
8010402e:	e8 0a ff ff ff       	call   80103f3d <fetchstr>
80104033:	83 c4 10             	add    $0x10,%esp
}
80104036:	c9                   	leave  
80104037:	c3                   	ret    
    return -1;
80104038:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010403d:	eb f7                	jmp    80104036 <argstr+0x2a>

8010403f <syscall>:
[SYS_munprotect] sys_munprotect,
};

void
syscall(void)
{
8010403f:	55                   	push   %ebp
80104040:	89 e5                	mov    %esp,%ebp
80104042:	53                   	push   %ebx
80104043:	83 ec 04             	sub    $0x4,%esp
  int num;
  struct proc *curproc = myproc();
80104046:	e8 d0 f1 ff ff       	call   8010321b <myproc>
8010404b:	89 c3                	mov    %eax,%ebx

  num = curproc->tf->eax;
8010404d:	8b 40 18             	mov    0x18(%eax),%eax
80104050:	8b 40 1c             	mov    0x1c(%eax),%eax
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
80104053:	8d 50 ff             	lea    -0x1(%eax),%edx
80104056:	83 fa 18             	cmp    $0x18,%edx
80104059:	77 17                	ja     80104072 <syscall+0x33>
8010405b:	8b 14 85 20 6f 10 80 	mov    -0x7fef90e0(,%eax,4),%edx
80104062:	85 d2                	test   %edx,%edx
80104064:	74 0c                	je     80104072 <syscall+0x33>
    curproc->tf->eax = syscalls[num]();
80104066:	ff d2                	call   *%edx
80104068:	89 c2                	mov    %eax,%edx
8010406a:	8b 43 18             	mov    0x18(%ebx),%eax
8010406d:	89 50 1c             	mov    %edx,0x1c(%eax)
80104070:	eb 1f                	jmp    80104091 <syscall+0x52>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
80104072:	8d 53 6c             	lea    0x6c(%ebx),%edx
    cprintf("%d %s: unknown sys call %d\n",
80104075:	50                   	push   %eax
80104076:	52                   	push   %edx
80104077:	ff 73 10             	push   0x10(%ebx)
8010407a:	68 fd 6e 10 80       	push   $0x80106efd
8010407f:	e8 83 c5 ff ff       	call   80100607 <cprintf>
    curproc->tf->eax = -1;
80104084:	8b 43 18             	mov    0x18(%ebx),%eax
80104087:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
8010408e:	83 c4 10             	add    $0x10,%esp
  }
}
80104091:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104094:	c9                   	leave  
80104095:	c3                   	ret    

80104096 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80104096:	55                   	push   %ebp
80104097:	89 e5                	mov    %esp,%ebp
80104099:	56                   	push   %esi
8010409a:	53                   	push   %ebx
8010409b:	83 ec 18             	sub    $0x18,%esp
8010409e:	89 d6                	mov    %edx,%esi
801040a0:	89 cb                	mov    %ecx,%ebx
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801040a2:	8d 55 f4             	lea    -0xc(%ebp),%edx
801040a5:	52                   	push   %edx
801040a6:	50                   	push   %eax
801040a7:	e8 d0 fe ff ff       	call   80103f7c <argint>
801040ac:	83 c4 10             	add    $0x10,%esp
801040af:	85 c0                	test   %eax,%eax
801040b1:	78 35                	js     801040e8 <argfd+0x52>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
801040b3:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801040b7:	77 28                	ja     801040e1 <argfd+0x4b>
801040b9:	e8 5d f1 ff ff       	call   8010321b <myproc>
801040be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801040c1:	8b 44 90 28          	mov    0x28(%eax,%edx,4),%eax
801040c5:	85 c0                	test   %eax,%eax
801040c7:	74 18                	je     801040e1 <argfd+0x4b>
    return -1;
  if(pfd)
801040c9:	85 f6                	test   %esi,%esi
801040cb:	74 02                	je     801040cf <argfd+0x39>
    *pfd = fd;
801040cd:	89 16                	mov    %edx,(%esi)
  if(pf)
801040cf:	85 db                	test   %ebx,%ebx
801040d1:	74 1c                	je     801040ef <argfd+0x59>
    *pf = f;
801040d3:	89 03                	mov    %eax,(%ebx)
  return 0;
801040d5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040da:	8d 65 f8             	lea    -0x8(%ebp),%esp
801040dd:	5b                   	pop    %ebx
801040de:	5e                   	pop    %esi
801040df:	5d                   	pop    %ebp
801040e0:	c3                   	ret    
    return -1;
801040e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040e6:	eb f2                	jmp    801040da <argfd+0x44>
    return -1;
801040e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040ed:	eb eb                	jmp    801040da <argfd+0x44>
  return 0;
801040ef:	b8 00 00 00 00       	mov    $0x0,%eax
801040f4:	eb e4                	jmp    801040da <argfd+0x44>

801040f6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801040f6:	55                   	push   %ebp
801040f7:	89 e5                	mov    %esp,%ebp
801040f9:	53                   	push   %ebx
801040fa:	83 ec 04             	sub    $0x4,%esp
801040fd:	89 c3                	mov    %eax,%ebx
  int fd;
  struct proc *curproc = myproc();
801040ff:	e8 17 f1 ff ff       	call   8010321b <myproc>
80104104:	89 c2                	mov    %eax,%edx

  for(fd = 0; fd < NOFILE; fd++){
80104106:	b8 00 00 00 00       	mov    $0x0,%eax
8010410b:	83 f8 0f             	cmp    $0xf,%eax
8010410e:	7f 12                	jg     80104122 <fdalloc+0x2c>
    if(curproc->ofile[fd] == 0){
80104110:	83 7c 82 28 00       	cmpl   $0x0,0x28(%edx,%eax,4)
80104115:	74 05                	je     8010411c <fdalloc+0x26>
  for(fd = 0; fd < NOFILE; fd++){
80104117:	83 c0 01             	add    $0x1,%eax
8010411a:	eb ef                	jmp    8010410b <fdalloc+0x15>
      curproc->ofile[fd] = f;
8010411c:	89 5c 82 28          	mov    %ebx,0x28(%edx,%eax,4)
      return fd;
80104120:	eb 05                	jmp    80104127 <fdalloc+0x31>
    }
  }
  return -1;
80104122:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104127:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010412a:	c9                   	leave  
8010412b:	c3                   	ret    

8010412c <isdirempty>:
}

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
8010412c:	55                   	push   %ebp
8010412d:	89 e5                	mov    %esp,%ebp
8010412f:	56                   	push   %esi
80104130:	53                   	push   %ebx
80104131:	83 ec 10             	sub    $0x10,%esp
80104134:	89 c3                	mov    %eax,%ebx
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80104136:	b8 20 00 00 00       	mov    $0x20,%eax
8010413b:	89 c6                	mov    %eax,%esi
8010413d:	39 43 58             	cmp    %eax,0x58(%ebx)
80104140:	76 2e                	jbe    80104170 <isdirempty+0x44>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80104142:	6a 10                	push   $0x10
80104144:	50                   	push   %eax
80104145:	8d 45 e8             	lea    -0x18(%ebp),%eax
80104148:	50                   	push   %eax
80104149:	53                   	push   %ebx
8010414a:	e8 12 d6 ff ff       	call   80101761 <readi>
8010414f:	83 c4 10             	add    $0x10,%esp
80104152:	83 f8 10             	cmp    $0x10,%eax
80104155:	75 0c                	jne    80104163 <isdirempty+0x37>
      panic("isdirempty: readi");
    if(de.inum != 0)
80104157:	66 83 7d e8 00       	cmpw   $0x0,-0x18(%ebp)
8010415c:	75 1e                	jne    8010417c <isdirempty+0x50>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010415e:	8d 46 10             	lea    0x10(%esi),%eax
80104161:	eb d8                	jmp    8010413b <isdirempty+0xf>
      panic("isdirempty: readi");
80104163:	83 ec 0c             	sub    $0xc,%esp
80104166:	68 88 6f 10 80       	push   $0x80106f88
8010416b:	e8 d8 c1 ff ff       	call   80100348 <panic>
      return 0;
  }
  return 1;
80104170:	b8 01 00 00 00       	mov    $0x1,%eax
}
80104175:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104178:	5b                   	pop    %ebx
80104179:	5e                   	pop    %esi
8010417a:	5d                   	pop    %ebp
8010417b:	c3                   	ret    
      return 0;
8010417c:	b8 00 00 00 00       	mov    $0x0,%eax
80104181:	eb f2                	jmp    80104175 <isdirempty+0x49>

80104183 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
80104183:	55                   	push   %ebp
80104184:	89 e5                	mov    %esp,%ebp
80104186:	57                   	push   %edi
80104187:	56                   	push   %esi
80104188:	53                   	push   %ebx
80104189:	83 ec 34             	sub    $0x34,%esp
8010418c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
8010418f:	89 4d d0             	mov    %ecx,-0x30(%ebp)
80104192:	8b 7d 08             	mov    0x8(%ebp),%edi
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80104195:	8d 55 da             	lea    -0x26(%ebp),%edx
80104198:	52                   	push   %edx
80104199:	50                   	push   %eax
8010419a:	e8 46 da ff ff       	call   80101be5 <nameiparent>
8010419f:	89 c6                	mov    %eax,%esi
801041a1:	83 c4 10             	add    $0x10,%esp
801041a4:	85 c0                	test   %eax,%eax
801041a6:	0f 84 33 01 00 00    	je     801042df <create+0x15c>
    return 0;
  ilock(dp);
801041ac:	83 ec 0c             	sub    $0xc,%esp
801041af:	50                   	push   %eax
801041b0:	e8 ba d3 ff ff       	call   8010156f <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
801041b5:	83 c4 0c             	add    $0xc,%esp
801041b8:	6a 00                	push   $0x0
801041ba:	8d 45 da             	lea    -0x26(%ebp),%eax
801041bd:	50                   	push   %eax
801041be:	56                   	push   %esi
801041bf:	e8 db d7 ff ff       	call   8010199f <dirlookup>
801041c4:	89 c3                	mov    %eax,%ebx
801041c6:	83 c4 10             	add    $0x10,%esp
801041c9:	85 c0                	test   %eax,%eax
801041cb:	74 3d                	je     8010420a <create+0x87>
    iunlockput(dp);
801041cd:	83 ec 0c             	sub    $0xc,%esp
801041d0:	56                   	push   %esi
801041d1:	e8 40 d5 ff ff       	call   80101716 <iunlockput>
    ilock(ip);
801041d6:	89 1c 24             	mov    %ebx,(%esp)
801041d9:	e8 91 d3 ff ff       	call   8010156f <ilock>
    if(type == T_FILE && ip->type == T_FILE)
801041de:	83 c4 10             	add    $0x10,%esp
801041e1:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
801041e6:	75 07                	jne    801041ef <create+0x6c>
801041e8:	66 83 7b 50 02       	cmpw   $0x2,0x50(%ebx)
801041ed:	74 11                	je     80104200 <create+0x7d>
      return ip;
    iunlockput(ip);
801041ef:	83 ec 0c             	sub    $0xc,%esp
801041f2:	53                   	push   %ebx
801041f3:	e8 1e d5 ff ff       	call   80101716 <iunlockput>
    return 0;
801041f8:	83 c4 10             	add    $0x10,%esp
801041fb:	bb 00 00 00 00       	mov    $0x0,%ebx
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
80104200:	89 d8                	mov    %ebx,%eax
80104202:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104205:	5b                   	pop    %ebx
80104206:	5e                   	pop    %esi
80104207:	5f                   	pop    %edi
80104208:	5d                   	pop    %ebp
80104209:	c3                   	ret    
  if((ip = ialloc(dp->dev, type)) == 0)
8010420a:	83 ec 08             	sub    $0x8,%esp
8010420d:	0f bf 45 d4          	movswl -0x2c(%ebp),%eax
80104211:	50                   	push   %eax
80104212:	ff 36                	push   (%esi)
80104214:	e8 53 d1 ff ff       	call   8010136c <ialloc>
80104219:	89 c3                	mov    %eax,%ebx
8010421b:	83 c4 10             	add    $0x10,%esp
8010421e:	85 c0                	test   %eax,%eax
80104220:	74 52                	je     80104274 <create+0xf1>
  ilock(ip);
80104222:	83 ec 0c             	sub    $0xc,%esp
80104225:	50                   	push   %eax
80104226:	e8 44 d3 ff ff       	call   8010156f <ilock>
  ip->major = major;
8010422b:	0f b7 45 d0          	movzwl -0x30(%ebp),%eax
8010422f:	66 89 43 52          	mov    %ax,0x52(%ebx)
  ip->minor = minor;
80104233:	66 89 7b 54          	mov    %di,0x54(%ebx)
  ip->nlink = 1;
80104237:	66 c7 43 56 01 00    	movw   $0x1,0x56(%ebx)
  iupdate(ip);
8010423d:	89 1c 24             	mov    %ebx,(%esp)
80104240:	e8 c9 d1 ff ff       	call   8010140e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
80104245:	83 c4 10             	add    $0x10,%esp
80104248:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
8010424d:	74 32                	je     80104281 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
8010424f:	83 ec 04             	sub    $0x4,%esp
80104252:	ff 73 04             	push   0x4(%ebx)
80104255:	8d 45 da             	lea    -0x26(%ebp),%eax
80104258:	50                   	push   %eax
80104259:	56                   	push   %esi
8010425a:	e8 bd d8 ff ff       	call   80101b1c <dirlink>
8010425f:	83 c4 10             	add    $0x10,%esp
80104262:	85 c0                	test   %eax,%eax
80104264:	78 6c                	js     801042d2 <create+0x14f>
  iunlockput(dp);
80104266:	83 ec 0c             	sub    $0xc,%esp
80104269:	56                   	push   %esi
8010426a:	e8 a7 d4 ff ff       	call   80101716 <iunlockput>
  return ip;
8010426f:	83 c4 10             	add    $0x10,%esp
80104272:	eb 8c                	jmp    80104200 <create+0x7d>
    panic("create: ialloc");
80104274:	83 ec 0c             	sub    $0xc,%esp
80104277:	68 9a 6f 10 80       	push   $0x80106f9a
8010427c:	e8 c7 c0 ff ff       	call   80100348 <panic>
    dp->nlink++;  // for ".."
80104281:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104285:	83 c0 01             	add    $0x1,%eax
80104288:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010428c:	83 ec 0c             	sub    $0xc,%esp
8010428f:	56                   	push   %esi
80104290:	e8 79 d1 ff ff       	call   8010140e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80104295:	83 c4 0c             	add    $0xc,%esp
80104298:	ff 73 04             	push   0x4(%ebx)
8010429b:	68 aa 6f 10 80       	push   $0x80106faa
801042a0:	53                   	push   %ebx
801042a1:	e8 76 d8 ff ff       	call   80101b1c <dirlink>
801042a6:	83 c4 10             	add    $0x10,%esp
801042a9:	85 c0                	test   %eax,%eax
801042ab:	78 18                	js     801042c5 <create+0x142>
801042ad:	83 ec 04             	sub    $0x4,%esp
801042b0:	ff 76 04             	push   0x4(%esi)
801042b3:	68 a9 6f 10 80       	push   $0x80106fa9
801042b8:	53                   	push   %ebx
801042b9:	e8 5e d8 ff ff       	call   80101b1c <dirlink>
801042be:	83 c4 10             	add    $0x10,%esp
801042c1:	85 c0                	test   %eax,%eax
801042c3:	79 8a                	jns    8010424f <create+0xcc>
      panic("create dots");
801042c5:	83 ec 0c             	sub    $0xc,%esp
801042c8:	68 ac 6f 10 80       	push   $0x80106fac
801042cd:	e8 76 c0 ff ff       	call   80100348 <panic>
    panic("create: dirlink");
801042d2:	83 ec 0c             	sub    $0xc,%esp
801042d5:	68 b8 6f 10 80       	push   $0x80106fb8
801042da:	e8 69 c0 ff ff       	call   80100348 <panic>
    return 0;
801042df:	89 c3                	mov    %eax,%ebx
801042e1:	e9 1a ff ff ff       	jmp    80104200 <create+0x7d>

801042e6 <sys_mprotect>:
{
801042e6:	55                   	push   %ebp
801042e7:	89 e5                	mov    %esp,%ebp
801042e9:	83 ec 20             	sub    $0x20,%esp
    if(argint(0, &addr) < 0){
801042ec:	8d 45 f4             	lea    -0xc(%ebp),%eax
801042ef:	50                   	push   %eax
801042f0:	6a 00                	push   $0x0
801042f2:	e8 85 fc ff ff       	call   80103f7c <argint>
801042f7:	83 c4 10             	add    $0x10,%esp
801042fa:	85 c0                	test   %eax,%eax
801042fc:	78 1c                	js     8010431a <sys_mprotect+0x34>
    if(argint(1, &len) < 0){
801042fe:	83 ec 08             	sub    $0x8,%esp
80104301:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104304:	50                   	push   %eax
80104305:	6a 01                	push   $0x1
80104307:	e8 70 fc ff ff       	call   80103f7c <argint>
8010430c:	83 c4 10             	add    $0x10,%esp
8010430f:	85 c0                	test   %eax,%eax
80104311:	78 0e                	js     80104321 <sys_mprotect+0x3b>
    return 0; //mprotect(addr,len);
80104313:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104318:	c9                   	leave  
80104319:	c3                   	ret    
        return -1;
8010431a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010431f:	eb f7                	jmp    80104318 <sys_mprotect+0x32>
        return -1;
80104321:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104326:	eb f0                	jmp    80104318 <sys_mprotect+0x32>

80104328 <sys_munprotect>:
{
80104328:	55                   	push   %ebp
80104329:	89 e5                	mov    %esp,%ebp
8010432b:	83 ec 20             	sub    $0x20,%esp
    if(argint(0, &addr) < 0){
8010432e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104331:	50                   	push   %eax
80104332:	6a 00                	push   $0x0
80104334:	e8 43 fc ff ff       	call   80103f7c <argint>
80104339:	83 c4 10             	add    $0x10,%esp
8010433c:	85 c0                	test   %eax,%eax
8010433e:	78 1c                	js     8010435c <sys_munprotect+0x34>
    if(argint(1, &len) < 0){
80104340:	83 ec 08             	sub    $0x8,%esp
80104343:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104346:	50                   	push   %eax
80104347:	6a 01                	push   $0x1
80104349:	e8 2e fc ff ff       	call   80103f7c <argint>
8010434e:	83 c4 10             	add    $0x10,%esp
80104351:	85 c0                	test   %eax,%eax
80104353:	78 0e                	js     80104363 <sys_munprotect+0x3b>
    return 0; //munprotect(addr,len);
80104355:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010435a:	c9                   	leave  
8010435b:	c3                   	ret    
        return -1;
8010435c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104361:	eb f7                	jmp    8010435a <sys_munprotect+0x32>
        return -1;
80104363:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104368:	eb f0                	jmp    8010435a <sys_munprotect+0x32>

8010436a <sys_settickets>:
{  
8010436a:	55                   	push   %ebp
8010436b:	89 e5                	mov    %esp,%ebp
8010436d:	53                   	push   %ebx
8010436e:	83 ec 14             	sub    $0x14,%esp
    struct proc* curr_proc = myproc();
80104371:	e8 a5 ee ff ff       	call   8010321b <myproc>
80104376:	89 c3                	mov    %eax,%ebx
    if(argint(0, &ticket) < 0){
80104378:	83 ec 08             	sub    $0x8,%esp
8010437b:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010437e:	50                   	push   %eax
8010437f:	6a 00                	push   $0x0
80104381:	e8 f6 fb ff ff       	call   80103f7c <argint>
80104386:	83 c4 10             	add    $0x10,%esp
80104389:	85 c0                	test   %eax,%eax
8010438b:	78 30                	js     801043bd <sys_settickets+0x53>
    if (ticket < 0 || ticket > 1){
8010438d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104390:	83 f8 01             	cmp    $0x1,%eax
80104393:	77 2f                	ja     801043c4 <sys_settickets+0x5a>
    if (ticket == 0){
80104395:	85 c0                	test   %eax,%eax
80104397:	75 07                	jne    801043a0 <sys_settickets+0x36>
        curr_proc -> priority = 0;
80104399:	c7 43 7c 00 00 00 00 	movl   $0x0,0x7c(%ebx)
    if (ticket == 1){
801043a0:	83 f8 01             	cmp    $0x1,%eax
801043a3:	74 0a                	je     801043af <sys_settickets+0x45>
    return 0;
801043a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043aa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801043ad:	c9                   	leave  
801043ae:	c3                   	ret    
        curr_proc -> priority = 1;
801043af:	c7 43 7c 01 00 00 00 	movl   $0x1,0x7c(%ebx)
    return 0;
801043b6:	b8 00 00 00 00       	mov    $0x0,%eax
801043bb:	eb ed                	jmp    801043aa <sys_settickets+0x40>
        return -1;
801043bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043c2:	eb e6                	jmp    801043aa <sys_settickets+0x40>
        return -1;
801043c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043c9:	eb df                	jmp    801043aa <sys_settickets+0x40>

801043cb <sys_getpinfo>:
{
801043cb:	55                   	push   %ebp
801043cc:	89 e5                	mov    %esp,%ebp
801043ce:	83 ec 1c             	sub    $0x1c,%esp
    if(argptr(0, (void*)&curr_state, sizeof(*curr_state)) < 0){
801043d1:	68 00 04 00 00       	push   $0x400
801043d6:	8d 45 f4             	lea    -0xc(%ebp),%eax
801043d9:	50                   	push   %eax
801043da:	6a 00                	push   $0x0
801043dc:	e8 c3 fb ff ff       	call   80103fa4 <argptr>
801043e1:	83 c4 10             	add    $0x10,%esp
801043e4:	85 c0                	test   %eax,%eax
801043e6:	78 15                	js     801043fd <sys_getpinfo+0x32>
    iterate_ptable(curr_state);
801043e8:	83 ec 0c             	sub    $0xc,%esp
801043eb:	ff 75 f4             	push   -0xc(%ebp)
801043ee:	e8 37 ed ff ff       	call   8010312a <iterate_ptable>
    return 0;
801043f3:	83 c4 10             	add    $0x10,%esp
801043f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043fb:	c9                   	leave  
801043fc:	c3                   	ret    
        return -1;
801043fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104402:	eb f7                	jmp    801043fb <sys_getpinfo+0x30>

80104404 <sys_dup>:
{
80104404:	55                   	push   %ebp
80104405:	89 e5                	mov    %esp,%ebp
80104407:	53                   	push   %ebx
80104408:	83 ec 14             	sub    $0x14,%esp
  if(argfd(0, 0, &f) < 0)
8010440b:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010440e:	ba 00 00 00 00       	mov    $0x0,%edx
80104413:	b8 00 00 00 00       	mov    $0x0,%eax
80104418:	e8 79 fc ff ff       	call   80104096 <argfd>
8010441d:	85 c0                	test   %eax,%eax
8010441f:	78 23                	js     80104444 <sys_dup+0x40>
  if((fd=fdalloc(f)) < 0)
80104421:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104424:	e8 cd fc ff ff       	call   801040f6 <fdalloc>
80104429:	89 c3                	mov    %eax,%ebx
8010442b:	85 c0                	test   %eax,%eax
8010442d:	78 1c                	js     8010444b <sys_dup+0x47>
  filedup(f);
8010442f:	83 ec 0c             	sub    $0xc,%esp
80104432:	ff 75 f4             	push   -0xc(%ebp)
80104435:	e8 44 c8 ff ff       	call   80100c7e <filedup>
  return fd;
8010443a:	83 c4 10             	add    $0x10,%esp
}
8010443d:	89 d8                	mov    %ebx,%eax
8010443f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104442:	c9                   	leave  
80104443:	c3                   	ret    
    return -1;
80104444:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104449:	eb f2                	jmp    8010443d <sys_dup+0x39>
    return -1;
8010444b:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104450:	eb eb                	jmp    8010443d <sys_dup+0x39>

80104452 <sys_read>:
{
80104452:	55                   	push   %ebp
80104453:	89 e5                	mov    %esp,%ebp
80104455:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80104458:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010445b:	ba 00 00 00 00       	mov    $0x0,%edx
80104460:	b8 00 00 00 00       	mov    $0x0,%eax
80104465:	e8 2c fc ff ff       	call   80104096 <argfd>
8010446a:	85 c0                	test   %eax,%eax
8010446c:	78 43                	js     801044b1 <sys_read+0x5f>
8010446e:	83 ec 08             	sub    $0x8,%esp
80104471:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104474:	50                   	push   %eax
80104475:	6a 02                	push   $0x2
80104477:	e8 00 fb ff ff       	call   80103f7c <argint>
8010447c:	83 c4 10             	add    $0x10,%esp
8010447f:	85 c0                	test   %eax,%eax
80104481:	78 2e                	js     801044b1 <sys_read+0x5f>
80104483:	83 ec 04             	sub    $0x4,%esp
80104486:	ff 75 f0             	push   -0x10(%ebp)
80104489:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010448c:	50                   	push   %eax
8010448d:	6a 01                	push   $0x1
8010448f:	e8 10 fb ff ff       	call   80103fa4 <argptr>
80104494:	83 c4 10             	add    $0x10,%esp
80104497:	85 c0                	test   %eax,%eax
80104499:	78 16                	js     801044b1 <sys_read+0x5f>
  return fileread(f, p, n);
8010449b:	83 ec 04             	sub    $0x4,%esp
8010449e:	ff 75 f0             	push   -0x10(%ebp)
801044a1:	ff 75 ec             	push   -0x14(%ebp)
801044a4:	ff 75 f4             	push   -0xc(%ebp)
801044a7:	e8 24 c9 ff ff       	call   80100dd0 <fileread>
801044ac:	83 c4 10             	add    $0x10,%esp
}
801044af:	c9                   	leave  
801044b0:	c3                   	ret    
    return -1;
801044b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044b6:	eb f7                	jmp    801044af <sys_read+0x5d>

801044b8 <sys_write>:
{
801044b8:	55                   	push   %ebp
801044b9:	89 e5                	mov    %esp,%ebp
801044bb:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801044be:	8d 4d f4             	lea    -0xc(%ebp),%ecx
801044c1:	ba 00 00 00 00       	mov    $0x0,%edx
801044c6:	b8 00 00 00 00       	mov    $0x0,%eax
801044cb:	e8 c6 fb ff ff       	call   80104096 <argfd>
801044d0:	85 c0                	test   %eax,%eax
801044d2:	78 43                	js     80104517 <sys_write+0x5f>
801044d4:	83 ec 08             	sub    $0x8,%esp
801044d7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801044da:	50                   	push   %eax
801044db:	6a 02                	push   $0x2
801044dd:	e8 9a fa ff ff       	call   80103f7c <argint>
801044e2:	83 c4 10             	add    $0x10,%esp
801044e5:	85 c0                	test   %eax,%eax
801044e7:	78 2e                	js     80104517 <sys_write+0x5f>
801044e9:	83 ec 04             	sub    $0x4,%esp
801044ec:	ff 75 f0             	push   -0x10(%ebp)
801044ef:	8d 45 ec             	lea    -0x14(%ebp),%eax
801044f2:	50                   	push   %eax
801044f3:	6a 01                	push   $0x1
801044f5:	e8 aa fa ff ff       	call   80103fa4 <argptr>
801044fa:	83 c4 10             	add    $0x10,%esp
801044fd:	85 c0                	test   %eax,%eax
801044ff:	78 16                	js     80104517 <sys_write+0x5f>
  return filewrite(f, p, n);
80104501:	83 ec 04             	sub    $0x4,%esp
80104504:	ff 75 f0             	push   -0x10(%ebp)
80104507:	ff 75 ec             	push   -0x14(%ebp)
8010450a:	ff 75 f4             	push   -0xc(%ebp)
8010450d:	e8 43 c9 ff ff       	call   80100e55 <filewrite>
80104512:	83 c4 10             	add    $0x10,%esp
}
80104515:	c9                   	leave  
80104516:	c3                   	ret    
    return -1;
80104517:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010451c:	eb f7                	jmp    80104515 <sys_write+0x5d>

8010451e <sys_close>:
{
8010451e:	55                   	push   %ebp
8010451f:	89 e5                	mov    %esp,%ebp
80104521:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, &fd, &f) < 0)
80104524:	8d 4d f0             	lea    -0x10(%ebp),%ecx
80104527:	8d 55 f4             	lea    -0xc(%ebp),%edx
8010452a:	b8 00 00 00 00       	mov    $0x0,%eax
8010452f:	e8 62 fb ff ff       	call   80104096 <argfd>
80104534:	85 c0                	test   %eax,%eax
80104536:	78 25                	js     8010455d <sys_close+0x3f>
  myproc()->ofile[fd] = 0;
80104538:	e8 de ec ff ff       	call   8010321b <myproc>
8010453d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104540:	c7 44 90 28 00 00 00 	movl   $0x0,0x28(%eax,%edx,4)
80104547:	00 
  fileclose(f);
80104548:	83 ec 0c             	sub    $0xc,%esp
8010454b:	ff 75 f0             	push   -0x10(%ebp)
8010454e:	e8 70 c7 ff ff       	call   80100cc3 <fileclose>
  return 0;
80104553:	83 c4 10             	add    $0x10,%esp
80104556:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010455b:	c9                   	leave  
8010455c:	c3                   	ret    
    return -1;
8010455d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104562:	eb f7                	jmp    8010455b <sys_close+0x3d>

80104564 <sys_fstat>:
{
80104564:	55                   	push   %ebp
80104565:	89 e5                	mov    %esp,%ebp
80104567:	83 ec 18             	sub    $0x18,%esp
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010456a:	8d 4d f4             	lea    -0xc(%ebp),%ecx
8010456d:	ba 00 00 00 00       	mov    $0x0,%edx
80104572:	b8 00 00 00 00       	mov    $0x0,%eax
80104577:	e8 1a fb ff ff       	call   80104096 <argfd>
8010457c:	85 c0                	test   %eax,%eax
8010457e:	78 2a                	js     801045aa <sys_fstat+0x46>
80104580:	83 ec 04             	sub    $0x4,%esp
80104583:	6a 14                	push   $0x14
80104585:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104588:	50                   	push   %eax
80104589:	6a 01                	push   $0x1
8010458b:	e8 14 fa ff ff       	call   80103fa4 <argptr>
80104590:	83 c4 10             	add    $0x10,%esp
80104593:	85 c0                	test   %eax,%eax
80104595:	78 13                	js     801045aa <sys_fstat+0x46>
  return filestat(f, st);
80104597:	83 ec 08             	sub    $0x8,%esp
8010459a:	ff 75 f0             	push   -0x10(%ebp)
8010459d:	ff 75 f4             	push   -0xc(%ebp)
801045a0:	e8 e4 c7 ff ff       	call   80100d89 <filestat>
801045a5:	83 c4 10             	add    $0x10,%esp
}
801045a8:	c9                   	leave  
801045a9:	c3                   	ret    
    return -1;
801045aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045af:	eb f7                	jmp    801045a8 <sys_fstat+0x44>

801045b1 <sys_link>:
{
801045b1:	55                   	push   %ebp
801045b2:	89 e5                	mov    %esp,%ebp
801045b4:	56                   	push   %esi
801045b5:	53                   	push   %ebx
801045b6:	83 ec 28             	sub    $0x28,%esp
  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801045b9:	8d 45 e0             	lea    -0x20(%ebp),%eax
801045bc:	50                   	push   %eax
801045bd:	6a 00                	push   $0x0
801045bf:	e8 48 fa ff ff       	call   8010400c <argstr>
801045c4:	83 c4 10             	add    $0x10,%esp
801045c7:	85 c0                	test   %eax,%eax
801045c9:	0f 88 d3 00 00 00    	js     801046a2 <sys_link+0xf1>
801045cf:	83 ec 08             	sub    $0x8,%esp
801045d2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801045d5:	50                   	push   %eax
801045d6:	6a 01                	push   $0x1
801045d8:	e8 2f fa ff ff       	call   8010400c <argstr>
801045dd:	83 c4 10             	add    $0x10,%esp
801045e0:	85 c0                	test   %eax,%eax
801045e2:	0f 88 ba 00 00 00    	js     801046a2 <sys_link+0xf1>
  begin_op();
801045e8:	e8 91 e1 ff ff       	call   8010277e <begin_op>
  if((ip = namei(old)) == 0){
801045ed:	83 ec 0c             	sub    $0xc,%esp
801045f0:	ff 75 e0             	push   -0x20(%ebp)
801045f3:	e8 d5 d5 ff ff       	call   80101bcd <namei>
801045f8:	89 c3                	mov    %eax,%ebx
801045fa:	83 c4 10             	add    $0x10,%esp
801045fd:	85 c0                	test   %eax,%eax
801045ff:	0f 84 a4 00 00 00    	je     801046a9 <sys_link+0xf8>
  ilock(ip);
80104605:	83 ec 0c             	sub    $0xc,%esp
80104608:	50                   	push   %eax
80104609:	e8 61 cf ff ff       	call   8010156f <ilock>
  if(ip->type == T_DIR){
8010460e:	83 c4 10             	add    $0x10,%esp
80104611:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104616:	0f 84 99 00 00 00    	je     801046b5 <sys_link+0x104>
  ip->nlink++;
8010461c:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
80104620:	83 c0 01             	add    $0x1,%eax
80104623:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104627:	83 ec 0c             	sub    $0xc,%esp
8010462a:	53                   	push   %ebx
8010462b:	e8 de cd ff ff       	call   8010140e <iupdate>
  iunlock(ip);
80104630:	89 1c 24             	mov    %ebx,(%esp)
80104633:	e8 f9 cf ff ff       	call   80101631 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
80104638:	83 c4 08             	add    $0x8,%esp
8010463b:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010463e:	50                   	push   %eax
8010463f:	ff 75 e4             	push   -0x1c(%ebp)
80104642:	e8 9e d5 ff ff       	call   80101be5 <nameiparent>
80104647:	89 c6                	mov    %eax,%esi
80104649:	83 c4 10             	add    $0x10,%esp
8010464c:	85 c0                	test   %eax,%eax
8010464e:	0f 84 85 00 00 00    	je     801046d9 <sys_link+0x128>
  ilock(dp);
80104654:	83 ec 0c             	sub    $0xc,%esp
80104657:	50                   	push   %eax
80104658:	e8 12 cf ff ff       	call   8010156f <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010465d:	83 c4 10             	add    $0x10,%esp
80104660:	8b 03                	mov    (%ebx),%eax
80104662:	39 06                	cmp    %eax,(%esi)
80104664:	75 67                	jne    801046cd <sys_link+0x11c>
80104666:	83 ec 04             	sub    $0x4,%esp
80104669:	ff 73 04             	push   0x4(%ebx)
8010466c:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010466f:	50                   	push   %eax
80104670:	56                   	push   %esi
80104671:	e8 a6 d4 ff ff       	call   80101b1c <dirlink>
80104676:	83 c4 10             	add    $0x10,%esp
80104679:	85 c0                	test   %eax,%eax
8010467b:	78 50                	js     801046cd <sys_link+0x11c>
  iunlockput(dp);
8010467d:	83 ec 0c             	sub    $0xc,%esp
80104680:	56                   	push   %esi
80104681:	e8 90 d0 ff ff       	call   80101716 <iunlockput>
  iput(ip);
80104686:	89 1c 24             	mov    %ebx,(%esp)
80104689:	e8 e8 cf ff ff       	call   80101676 <iput>
  end_op();
8010468e:	e8 65 e1 ff ff       	call   801027f8 <end_op>
  return 0;
80104693:	83 c4 10             	add    $0x10,%esp
80104696:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010469b:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010469e:	5b                   	pop    %ebx
8010469f:	5e                   	pop    %esi
801046a0:	5d                   	pop    %ebp
801046a1:	c3                   	ret    
    return -1;
801046a2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046a7:	eb f2                	jmp    8010469b <sys_link+0xea>
    end_op();
801046a9:	e8 4a e1 ff ff       	call   801027f8 <end_op>
    return -1;
801046ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046b3:	eb e6                	jmp    8010469b <sys_link+0xea>
    iunlockput(ip);
801046b5:	83 ec 0c             	sub    $0xc,%esp
801046b8:	53                   	push   %ebx
801046b9:	e8 58 d0 ff ff       	call   80101716 <iunlockput>
    end_op();
801046be:	e8 35 e1 ff ff       	call   801027f8 <end_op>
    return -1;
801046c3:	83 c4 10             	add    $0x10,%esp
801046c6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801046cb:	eb ce                	jmp    8010469b <sys_link+0xea>
    iunlockput(dp);
801046cd:	83 ec 0c             	sub    $0xc,%esp
801046d0:	56                   	push   %esi
801046d1:	e8 40 d0 ff ff       	call   80101716 <iunlockput>
    goto bad;
801046d6:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
801046d9:	83 ec 0c             	sub    $0xc,%esp
801046dc:	53                   	push   %ebx
801046dd:	e8 8d ce ff ff       	call   8010156f <ilock>
  ip->nlink--;
801046e2:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
801046e6:	83 e8 01             	sub    $0x1,%eax
801046e9:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
801046ed:	89 1c 24             	mov    %ebx,(%esp)
801046f0:	e8 19 cd ff ff       	call   8010140e <iupdate>
  iunlockput(ip);
801046f5:	89 1c 24             	mov    %ebx,(%esp)
801046f8:	e8 19 d0 ff ff       	call   80101716 <iunlockput>
  end_op();
801046fd:	e8 f6 e0 ff ff       	call   801027f8 <end_op>
  return -1;
80104702:	83 c4 10             	add    $0x10,%esp
80104705:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010470a:	eb 8f                	jmp    8010469b <sys_link+0xea>

8010470c <sys_unlink>:
{
8010470c:	55                   	push   %ebp
8010470d:	89 e5                	mov    %esp,%ebp
8010470f:	57                   	push   %edi
80104710:	56                   	push   %esi
80104711:	53                   	push   %ebx
80104712:	83 ec 44             	sub    $0x44,%esp
  if(argstr(0, &path) < 0)
80104715:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104718:	50                   	push   %eax
80104719:	6a 00                	push   $0x0
8010471b:	e8 ec f8 ff ff       	call   8010400c <argstr>
80104720:	83 c4 10             	add    $0x10,%esp
80104723:	85 c0                	test   %eax,%eax
80104725:	0f 88 83 01 00 00    	js     801048ae <sys_unlink+0x1a2>
  begin_op();
8010472b:	e8 4e e0 ff ff       	call   8010277e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80104730:	83 ec 08             	sub    $0x8,%esp
80104733:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104736:	50                   	push   %eax
80104737:	ff 75 c4             	push   -0x3c(%ebp)
8010473a:	e8 a6 d4 ff ff       	call   80101be5 <nameiparent>
8010473f:	89 c6                	mov    %eax,%esi
80104741:	83 c4 10             	add    $0x10,%esp
80104744:	85 c0                	test   %eax,%eax
80104746:	0f 84 ed 00 00 00    	je     80104839 <sys_unlink+0x12d>
  ilock(dp);
8010474c:	83 ec 0c             	sub    $0xc,%esp
8010474f:	50                   	push   %eax
80104750:	e8 1a ce ff ff       	call   8010156f <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80104755:	83 c4 08             	add    $0x8,%esp
80104758:	68 aa 6f 10 80       	push   $0x80106faa
8010475d:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104760:	50                   	push   %eax
80104761:	e8 24 d2 ff ff       	call   8010198a <namecmp>
80104766:	83 c4 10             	add    $0x10,%esp
80104769:	85 c0                	test   %eax,%eax
8010476b:	0f 84 fc 00 00 00    	je     8010486d <sys_unlink+0x161>
80104771:	83 ec 08             	sub    $0x8,%esp
80104774:	68 a9 6f 10 80       	push   $0x80106fa9
80104779:	8d 45 ca             	lea    -0x36(%ebp),%eax
8010477c:	50                   	push   %eax
8010477d:	e8 08 d2 ff ff       	call   8010198a <namecmp>
80104782:	83 c4 10             	add    $0x10,%esp
80104785:	85 c0                	test   %eax,%eax
80104787:	0f 84 e0 00 00 00    	je     8010486d <sys_unlink+0x161>
  if((ip = dirlookup(dp, name, &off)) == 0)
8010478d:	83 ec 04             	sub    $0x4,%esp
80104790:	8d 45 c0             	lea    -0x40(%ebp),%eax
80104793:	50                   	push   %eax
80104794:	8d 45 ca             	lea    -0x36(%ebp),%eax
80104797:	50                   	push   %eax
80104798:	56                   	push   %esi
80104799:	e8 01 d2 ff ff       	call   8010199f <dirlookup>
8010479e:	89 c3                	mov    %eax,%ebx
801047a0:	83 c4 10             	add    $0x10,%esp
801047a3:	85 c0                	test   %eax,%eax
801047a5:	0f 84 c2 00 00 00    	je     8010486d <sys_unlink+0x161>
  ilock(ip);
801047ab:	83 ec 0c             	sub    $0xc,%esp
801047ae:	50                   	push   %eax
801047af:	e8 bb cd ff ff       	call   8010156f <ilock>
  if(ip->nlink < 1)
801047b4:	83 c4 10             	add    $0x10,%esp
801047b7:	66 83 7b 56 00       	cmpw   $0x0,0x56(%ebx)
801047bc:	0f 8e 83 00 00 00    	jle    80104845 <sys_unlink+0x139>
  if(ip->type == T_DIR && !isdirempty(ip)){
801047c2:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047c7:	0f 84 85 00 00 00    	je     80104852 <sys_unlink+0x146>
  memset(&de, 0, sizeof(de));
801047cd:	83 ec 04             	sub    $0x4,%esp
801047d0:	6a 10                	push   $0x10
801047d2:	6a 00                	push   $0x0
801047d4:	8d 7d d8             	lea    -0x28(%ebp),%edi
801047d7:	57                   	push   %edi
801047d8:	e8 4f f5 ff ff       	call   80103d2c <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801047dd:	6a 10                	push   $0x10
801047df:	ff 75 c0             	push   -0x40(%ebp)
801047e2:	57                   	push   %edi
801047e3:	56                   	push   %esi
801047e4:	e8 75 d0 ff ff       	call   8010185e <writei>
801047e9:	83 c4 20             	add    $0x20,%esp
801047ec:	83 f8 10             	cmp    $0x10,%eax
801047ef:	0f 85 90 00 00 00    	jne    80104885 <sys_unlink+0x179>
  if(ip->type == T_DIR){
801047f5:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
801047fa:	0f 84 92 00 00 00    	je     80104892 <sys_unlink+0x186>
  iunlockput(dp);
80104800:	83 ec 0c             	sub    $0xc,%esp
80104803:	56                   	push   %esi
80104804:	e8 0d cf ff ff       	call   80101716 <iunlockput>
  ip->nlink--;
80104809:	0f b7 43 56          	movzwl 0x56(%ebx),%eax
8010480d:	83 e8 01             	sub    $0x1,%eax
80104810:	66 89 43 56          	mov    %ax,0x56(%ebx)
  iupdate(ip);
80104814:	89 1c 24             	mov    %ebx,(%esp)
80104817:	e8 f2 cb ff ff       	call   8010140e <iupdate>
  iunlockput(ip);
8010481c:	89 1c 24             	mov    %ebx,(%esp)
8010481f:	e8 f2 ce ff ff       	call   80101716 <iunlockput>
  end_op();
80104824:	e8 cf df ff ff       	call   801027f8 <end_op>
  return 0;
80104829:	83 c4 10             	add    $0x10,%esp
8010482c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104831:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104834:	5b                   	pop    %ebx
80104835:	5e                   	pop    %esi
80104836:	5f                   	pop    %edi
80104837:	5d                   	pop    %ebp
80104838:	c3                   	ret    
    end_op();
80104839:	e8 ba df ff ff       	call   801027f8 <end_op>
    return -1;
8010483e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104843:	eb ec                	jmp    80104831 <sys_unlink+0x125>
    panic("unlink: nlink < 1");
80104845:	83 ec 0c             	sub    $0xc,%esp
80104848:	68 c8 6f 10 80       	push   $0x80106fc8
8010484d:	e8 f6 ba ff ff       	call   80100348 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80104852:	89 d8                	mov    %ebx,%eax
80104854:	e8 d3 f8 ff ff       	call   8010412c <isdirempty>
80104859:	85 c0                	test   %eax,%eax
8010485b:	0f 85 6c ff ff ff    	jne    801047cd <sys_unlink+0xc1>
    iunlockput(ip);
80104861:	83 ec 0c             	sub    $0xc,%esp
80104864:	53                   	push   %ebx
80104865:	e8 ac ce ff ff       	call   80101716 <iunlockput>
    goto bad;
8010486a:	83 c4 10             	add    $0x10,%esp
  iunlockput(dp);
8010486d:	83 ec 0c             	sub    $0xc,%esp
80104870:	56                   	push   %esi
80104871:	e8 a0 ce ff ff       	call   80101716 <iunlockput>
  end_op();
80104876:	e8 7d df ff ff       	call   801027f8 <end_op>
  return -1;
8010487b:	83 c4 10             	add    $0x10,%esp
8010487e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104883:	eb ac                	jmp    80104831 <sys_unlink+0x125>
    panic("unlink: writei");
80104885:	83 ec 0c             	sub    $0xc,%esp
80104888:	68 da 6f 10 80       	push   $0x80106fda
8010488d:	e8 b6 ba ff ff       	call   80100348 <panic>
    dp->nlink--;
80104892:	0f b7 46 56          	movzwl 0x56(%esi),%eax
80104896:	83 e8 01             	sub    $0x1,%eax
80104899:	66 89 46 56          	mov    %ax,0x56(%esi)
    iupdate(dp);
8010489d:	83 ec 0c             	sub    $0xc,%esp
801048a0:	56                   	push   %esi
801048a1:	e8 68 cb ff ff       	call   8010140e <iupdate>
801048a6:	83 c4 10             	add    $0x10,%esp
801048a9:	e9 52 ff ff ff       	jmp    80104800 <sys_unlink+0xf4>
    return -1;
801048ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801048b3:	e9 79 ff ff ff       	jmp    80104831 <sys_unlink+0x125>

801048b8 <sys_open>:

int
sys_open(void)
{
801048b8:	55                   	push   %ebp
801048b9:	89 e5                	mov    %esp,%ebp
801048bb:	57                   	push   %edi
801048bc:	56                   	push   %esi
801048bd:	53                   	push   %ebx
801048be:	83 ec 24             	sub    $0x24,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
801048c1:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801048c4:	50                   	push   %eax
801048c5:	6a 00                	push   $0x0
801048c7:	e8 40 f7 ff ff       	call   8010400c <argstr>
801048cc:	83 c4 10             	add    $0x10,%esp
801048cf:	85 c0                	test   %eax,%eax
801048d1:	0f 88 a0 00 00 00    	js     80104977 <sys_open+0xbf>
801048d7:	83 ec 08             	sub    $0x8,%esp
801048da:	8d 45 e0             	lea    -0x20(%ebp),%eax
801048dd:	50                   	push   %eax
801048de:	6a 01                	push   $0x1
801048e0:	e8 97 f6 ff ff       	call   80103f7c <argint>
801048e5:	83 c4 10             	add    $0x10,%esp
801048e8:	85 c0                	test   %eax,%eax
801048ea:	0f 88 87 00 00 00    	js     80104977 <sys_open+0xbf>
    return -1;

  begin_op();
801048f0:	e8 89 de ff ff       	call   8010277e <begin_op>

  if(omode & O_CREATE){
801048f5:	f6 45 e1 02          	testb  $0x2,-0x1f(%ebp)
801048f9:	0f 84 8b 00 00 00    	je     8010498a <sys_open+0xd2>
    ip = create(path, T_FILE, 0, 0);
801048ff:	83 ec 0c             	sub    $0xc,%esp
80104902:	6a 00                	push   $0x0
80104904:	b9 00 00 00 00       	mov    $0x0,%ecx
80104909:	ba 02 00 00 00       	mov    $0x2,%edx
8010490e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104911:	e8 6d f8 ff ff       	call   80104183 <create>
80104916:	89 c6                	mov    %eax,%esi
    if(ip == 0){
80104918:	83 c4 10             	add    $0x10,%esp
8010491b:	85 c0                	test   %eax,%eax
8010491d:	74 5f                	je     8010497e <sys_open+0xc6>
      end_op();
      return -1;
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
8010491f:	e8 f9 c2 ff ff       	call   80100c1d <filealloc>
80104924:	89 c3                	mov    %eax,%ebx
80104926:	85 c0                	test   %eax,%eax
80104928:	0f 84 b5 00 00 00    	je     801049e3 <sys_open+0x12b>
8010492e:	e8 c3 f7 ff ff       	call   801040f6 <fdalloc>
80104933:	89 c7                	mov    %eax,%edi
80104935:	85 c0                	test   %eax,%eax
80104937:	0f 88 a6 00 00 00    	js     801049e3 <sys_open+0x12b>
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
8010493d:	83 ec 0c             	sub    $0xc,%esp
80104940:	56                   	push   %esi
80104941:	e8 eb cc ff ff       	call   80101631 <iunlock>
  end_op();
80104946:	e8 ad de ff ff       	call   801027f8 <end_op>

  f->type = FD_INODE;
8010494b:	c7 03 02 00 00 00    	movl   $0x2,(%ebx)
  f->ip = ip;
80104951:	89 73 10             	mov    %esi,0x10(%ebx)
  f->off = 0;
80104954:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
  f->readable = !(omode & O_WRONLY);
8010495b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010495e:	83 c4 10             	add    $0x10,%esp
80104961:	a8 01                	test   $0x1,%al
80104963:	0f 94 43 08          	sete   0x8(%ebx)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80104967:	a8 03                	test   $0x3,%al
80104969:	0f 95 43 09          	setne  0x9(%ebx)
  return fd;
}
8010496d:	89 f8                	mov    %edi,%eax
8010496f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104972:	5b                   	pop    %ebx
80104973:	5e                   	pop    %esi
80104974:	5f                   	pop    %edi
80104975:	5d                   	pop    %ebp
80104976:	c3                   	ret    
    return -1;
80104977:	bf ff ff ff ff       	mov    $0xffffffff,%edi
8010497c:	eb ef                	jmp    8010496d <sys_open+0xb5>
      end_op();
8010497e:	e8 75 de ff ff       	call   801027f8 <end_op>
      return -1;
80104983:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104988:	eb e3                	jmp    8010496d <sys_open+0xb5>
    if((ip = namei(path)) == 0){
8010498a:	83 ec 0c             	sub    $0xc,%esp
8010498d:	ff 75 e4             	push   -0x1c(%ebp)
80104990:	e8 38 d2 ff ff       	call   80101bcd <namei>
80104995:	89 c6                	mov    %eax,%esi
80104997:	83 c4 10             	add    $0x10,%esp
8010499a:	85 c0                	test   %eax,%eax
8010499c:	74 39                	je     801049d7 <sys_open+0x11f>
    ilock(ip);
8010499e:	83 ec 0c             	sub    $0xc,%esp
801049a1:	50                   	push   %eax
801049a2:	e8 c8 cb ff ff       	call   8010156f <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
801049a7:	83 c4 10             	add    $0x10,%esp
801049aa:	66 83 7e 50 01       	cmpw   $0x1,0x50(%esi)
801049af:	0f 85 6a ff ff ff    	jne    8010491f <sys_open+0x67>
801049b5:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801049b9:	0f 84 60 ff ff ff    	je     8010491f <sys_open+0x67>
      iunlockput(ip);
801049bf:	83 ec 0c             	sub    $0xc,%esp
801049c2:	56                   	push   %esi
801049c3:	e8 4e cd ff ff       	call   80101716 <iunlockput>
      end_op();
801049c8:	e8 2b de ff ff       	call   801027f8 <end_op>
      return -1;
801049cd:	83 c4 10             	add    $0x10,%esp
801049d0:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049d5:	eb 96                	jmp    8010496d <sys_open+0xb5>
      end_op();
801049d7:	e8 1c de ff ff       	call   801027f8 <end_op>
      return -1;
801049dc:	bf ff ff ff ff       	mov    $0xffffffff,%edi
801049e1:	eb 8a                	jmp    8010496d <sys_open+0xb5>
    if(f)
801049e3:	85 db                	test   %ebx,%ebx
801049e5:	74 0c                	je     801049f3 <sys_open+0x13b>
      fileclose(f);
801049e7:	83 ec 0c             	sub    $0xc,%esp
801049ea:	53                   	push   %ebx
801049eb:	e8 d3 c2 ff ff       	call   80100cc3 <fileclose>
801049f0:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
801049f3:	83 ec 0c             	sub    $0xc,%esp
801049f6:	56                   	push   %esi
801049f7:	e8 1a cd ff ff       	call   80101716 <iunlockput>
    end_op();
801049fc:	e8 f7 dd ff ff       	call   801027f8 <end_op>
    return -1;
80104a01:	83 c4 10             	add    $0x10,%esp
80104a04:	bf ff ff ff ff       	mov    $0xffffffff,%edi
80104a09:	e9 5f ff ff ff       	jmp    8010496d <sys_open+0xb5>

80104a0e <sys_mkdir>:

int
sys_mkdir(void)
{
80104a0e:	55                   	push   %ebp
80104a0f:	89 e5                	mov    %esp,%ebp
80104a11:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80104a14:	e8 65 dd ff ff       	call   8010277e <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80104a19:	83 ec 08             	sub    $0x8,%esp
80104a1c:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a1f:	50                   	push   %eax
80104a20:	6a 00                	push   $0x0
80104a22:	e8 e5 f5 ff ff       	call   8010400c <argstr>
80104a27:	83 c4 10             	add    $0x10,%esp
80104a2a:	85 c0                	test   %eax,%eax
80104a2c:	78 36                	js     80104a64 <sys_mkdir+0x56>
80104a2e:	83 ec 0c             	sub    $0xc,%esp
80104a31:	6a 00                	push   $0x0
80104a33:	b9 00 00 00 00       	mov    $0x0,%ecx
80104a38:	ba 01 00 00 00       	mov    $0x1,%edx
80104a3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a40:	e8 3e f7 ff ff       	call   80104183 <create>
80104a45:	83 c4 10             	add    $0x10,%esp
80104a48:	85 c0                	test   %eax,%eax
80104a4a:	74 18                	je     80104a64 <sys_mkdir+0x56>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104a4c:	83 ec 0c             	sub    $0xc,%esp
80104a4f:	50                   	push   %eax
80104a50:	e8 c1 cc ff ff       	call   80101716 <iunlockput>
  end_op();
80104a55:	e8 9e dd ff ff       	call   801027f8 <end_op>
  return 0;
80104a5a:	83 c4 10             	add    $0x10,%esp
80104a5d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104a62:	c9                   	leave  
80104a63:	c3                   	ret    
    end_op();
80104a64:	e8 8f dd ff ff       	call   801027f8 <end_op>
    return -1;
80104a69:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104a6e:	eb f2                	jmp    80104a62 <sys_mkdir+0x54>

80104a70 <sys_mknod>:

int
sys_mknod(void)
{
80104a70:	55                   	push   %ebp
80104a71:	89 e5                	mov    %esp,%ebp
80104a73:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80104a76:	e8 03 dd ff ff       	call   8010277e <begin_op>
  if((argstr(0, &path)) < 0 ||
80104a7b:	83 ec 08             	sub    $0x8,%esp
80104a7e:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104a81:	50                   	push   %eax
80104a82:	6a 00                	push   $0x0
80104a84:	e8 83 f5 ff ff       	call   8010400c <argstr>
80104a89:	83 c4 10             	add    $0x10,%esp
80104a8c:	85 c0                	test   %eax,%eax
80104a8e:	78 62                	js     80104af2 <sys_mknod+0x82>
     argint(1, &major) < 0 ||
80104a90:	83 ec 08             	sub    $0x8,%esp
80104a93:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104a96:	50                   	push   %eax
80104a97:	6a 01                	push   $0x1
80104a99:	e8 de f4 ff ff       	call   80103f7c <argint>
  if((argstr(0, &path)) < 0 ||
80104a9e:	83 c4 10             	add    $0x10,%esp
80104aa1:	85 c0                	test   %eax,%eax
80104aa3:	78 4d                	js     80104af2 <sys_mknod+0x82>
     argint(2, &minor) < 0 ||
80104aa5:	83 ec 08             	sub    $0x8,%esp
80104aa8:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104aab:	50                   	push   %eax
80104aac:	6a 02                	push   $0x2
80104aae:	e8 c9 f4 ff ff       	call   80103f7c <argint>
     argint(1, &major) < 0 ||
80104ab3:	83 c4 10             	add    $0x10,%esp
80104ab6:	85 c0                	test   %eax,%eax
80104ab8:	78 38                	js     80104af2 <sys_mknod+0x82>
     (ip = create(path, T_DEV, major, minor)) == 0){
80104aba:	0f bf 4d f0          	movswl -0x10(%ebp),%ecx
80104abe:	83 ec 0c             	sub    $0xc,%esp
80104ac1:	0f bf 45 ec          	movswl -0x14(%ebp),%eax
80104ac5:	50                   	push   %eax
80104ac6:	ba 03 00 00 00       	mov    $0x3,%edx
80104acb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ace:	e8 b0 f6 ff ff       	call   80104183 <create>
     argint(2, &minor) < 0 ||
80104ad3:	83 c4 10             	add    $0x10,%esp
80104ad6:	85 c0                	test   %eax,%eax
80104ad8:	74 18                	je     80104af2 <sys_mknod+0x82>
    end_op();
    return -1;
  }
  iunlockput(ip);
80104ada:	83 ec 0c             	sub    $0xc,%esp
80104add:	50                   	push   %eax
80104ade:	e8 33 cc ff ff       	call   80101716 <iunlockput>
  end_op();
80104ae3:	e8 10 dd ff ff       	call   801027f8 <end_op>
  return 0;
80104ae8:	83 c4 10             	add    $0x10,%esp
80104aeb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104af0:	c9                   	leave  
80104af1:	c3                   	ret    
    end_op();
80104af2:	e8 01 dd ff ff       	call   801027f8 <end_op>
    return -1;
80104af7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104afc:	eb f2                	jmp    80104af0 <sys_mknod+0x80>

80104afe <sys_chdir>:

int
sys_chdir(void)
{
80104afe:	55                   	push   %ebp
80104aff:	89 e5                	mov    %esp,%ebp
80104b01:	56                   	push   %esi
80104b02:	53                   	push   %ebx
80104b03:	83 ec 10             	sub    $0x10,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
80104b06:	e8 10 e7 ff ff       	call   8010321b <myproc>
80104b0b:	89 c6                	mov    %eax,%esi
  
  begin_op();
80104b0d:	e8 6c dc ff ff       	call   8010277e <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80104b12:	83 ec 08             	sub    $0x8,%esp
80104b15:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104b18:	50                   	push   %eax
80104b19:	6a 00                	push   $0x0
80104b1b:	e8 ec f4 ff ff       	call   8010400c <argstr>
80104b20:	83 c4 10             	add    $0x10,%esp
80104b23:	85 c0                	test   %eax,%eax
80104b25:	78 52                	js     80104b79 <sys_chdir+0x7b>
80104b27:	83 ec 0c             	sub    $0xc,%esp
80104b2a:	ff 75 f4             	push   -0xc(%ebp)
80104b2d:	e8 9b d0 ff ff       	call   80101bcd <namei>
80104b32:	89 c3                	mov    %eax,%ebx
80104b34:	83 c4 10             	add    $0x10,%esp
80104b37:	85 c0                	test   %eax,%eax
80104b39:	74 3e                	je     80104b79 <sys_chdir+0x7b>
    end_op();
    return -1;
  }
  ilock(ip);
80104b3b:	83 ec 0c             	sub    $0xc,%esp
80104b3e:	50                   	push   %eax
80104b3f:	e8 2b ca ff ff       	call   8010156f <ilock>
  if(ip->type != T_DIR){
80104b44:	83 c4 10             	add    $0x10,%esp
80104b47:	66 83 7b 50 01       	cmpw   $0x1,0x50(%ebx)
80104b4c:	75 37                	jne    80104b85 <sys_chdir+0x87>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
80104b4e:	83 ec 0c             	sub    $0xc,%esp
80104b51:	53                   	push   %ebx
80104b52:	e8 da ca ff ff       	call   80101631 <iunlock>
  iput(curproc->cwd);
80104b57:	83 c4 04             	add    $0x4,%esp
80104b5a:	ff 76 68             	push   0x68(%esi)
80104b5d:	e8 14 cb ff ff       	call   80101676 <iput>
  end_op();
80104b62:	e8 91 dc ff ff       	call   801027f8 <end_op>
  curproc->cwd = ip;
80104b67:	89 5e 68             	mov    %ebx,0x68(%esi)
  return 0;
80104b6a:	83 c4 10             	add    $0x10,%esp
80104b6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104b72:	8d 65 f8             	lea    -0x8(%ebp),%esp
80104b75:	5b                   	pop    %ebx
80104b76:	5e                   	pop    %esi
80104b77:	5d                   	pop    %ebp
80104b78:	c3                   	ret    
    end_op();
80104b79:	e8 7a dc ff ff       	call   801027f8 <end_op>
    return -1;
80104b7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b83:	eb ed                	jmp    80104b72 <sys_chdir+0x74>
    iunlockput(ip);
80104b85:	83 ec 0c             	sub    $0xc,%esp
80104b88:	53                   	push   %ebx
80104b89:	e8 88 cb ff ff       	call   80101716 <iunlockput>
    end_op();
80104b8e:	e8 65 dc ff ff       	call   801027f8 <end_op>
    return -1;
80104b93:	83 c4 10             	add    $0x10,%esp
80104b96:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104b9b:	eb d5                	jmp    80104b72 <sys_chdir+0x74>

80104b9d <sys_exec>:

int
sys_exec(void)
{
80104b9d:	55                   	push   %ebp
80104b9e:	89 e5                	mov    %esp,%ebp
80104ba0:	53                   	push   %ebx
80104ba1:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80104ba7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104baa:	50                   	push   %eax
80104bab:	6a 00                	push   $0x0
80104bad:	e8 5a f4 ff ff       	call   8010400c <argstr>
80104bb2:	83 c4 10             	add    $0x10,%esp
80104bb5:	85 c0                	test   %eax,%eax
80104bb7:	78 38                	js     80104bf1 <sys_exec+0x54>
80104bb9:	83 ec 08             	sub    $0x8,%esp
80104bbc:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80104bc2:	50                   	push   %eax
80104bc3:	6a 01                	push   $0x1
80104bc5:	e8 b2 f3 ff ff       	call   80103f7c <argint>
80104bca:	83 c4 10             	add    $0x10,%esp
80104bcd:	85 c0                	test   %eax,%eax
80104bcf:	78 20                	js     80104bf1 <sys_exec+0x54>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
80104bd1:	83 ec 04             	sub    $0x4,%esp
80104bd4:	68 80 00 00 00       	push   $0x80
80104bd9:	6a 00                	push   $0x0
80104bdb:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104be1:	50                   	push   %eax
80104be2:	e8 45 f1 ff ff       	call   80103d2c <memset>
80104be7:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80104bea:	bb 00 00 00 00       	mov    $0x0,%ebx
80104bef:	eb 2c                	jmp    80104c1d <sys_exec+0x80>
    return -1;
80104bf1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104bf6:	eb 78                	jmp    80104c70 <sys_exec+0xd3>
    if(i >= NELEM(argv))
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
      return -1;
    if(uarg == 0){
      argv[i] = 0;
80104bf8:	c7 84 9d 74 ff ff ff 	movl   $0x0,-0x8c(%ebp,%ebx,4)
80104bff:	00 00 00 00 
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80104c03:	83 ec 08             	sub    $0x8,%esp
80104c06:	8d 85 74 ff ff ff    	lea    -0x8c(%ebp),%eax
80104c0c:	50                   	push   %eax
80104c0d:	ff 75 f4             	push   -0xc(%ebp)
80104c10:	e8 b9 bc ff ff       	call   801008ce <exec>
80104c15:	83 c4 10             	add    $0x10,%esp
80104c18:	eb 56                	jmp    80104c70 <sys_exec+0xd3>
  for(i=0;; i++){
80104c1a:	83 c3 01             	add    $0x1,%ebx
    if(i >= NELEM(argv))
80104c1d:	83 fb 1f             	cmp    $0x1f,%ebx
80104c20:	77 49                	ja     80104c6b <sys_exec+0xce>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
80104c22:	83 ec 08             	sub    $0x8,%esp
80104c25:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80104c2b:	50                   	push   %eax
80104c2c:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
80104c32:	8d 04 98             	lea    (%eax,%ebx,4),%eax
80104c35:	50                   	push   %eax
80104c36:	e8 c7 f2 ff ff       	call   80103f02 <fetchint>
80104c3b:	83 c4 10             	add    $0x10,%esp
80104c3e:	85 c0                	test   %eax,%eax
80104c40:	78 33                	js     80104c75 <sys_exec+0xd8>
    if(uarg == 0){
80104c42:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80104c48:	85 c0                	test   %eax,%eax
80104c4a:	74 ac                	je     80104bf8 <sys_exec+0x5b>
    if(fetchstr(uarg, &argv[i]) < 0)
80104c4c:	83 ec 08             	sub    $0x8,%esp
80104c4f:	8d 94 9d 74 ff ff ff 	lea    -0x8c(%ebp,%ebx,4),%edx
80104c56:	52                   	push   %edx
80104c57:	50                   	push   %eax
80104c58:	e8 e0 f2 ff ff       	call   80103f3d <fetchstr>
80104c5d:	83 c4 10             	add    $0x10,%esp
80104c60:	85 c0                	test   %eax,%eax
80104c62:	79 b6                	jns    80104c1a <sys_exec+0x7d>
      return -1;
80104c64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c69:	eb 05                	jmp    80104c70 <sys_exec+0xd3>
      return -1;
80104c6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104c70:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104c73:	c9                   	leave  
80104c74:	c3                   	ret    
      return -1;
80104c75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104c7a:	eb f4                	jmp    80104c70 <sys_exec+0xd3>

80104c7c <sys_pipe>:

int
sys_pipe(void)
{
80104c7c:	55                   	push   %ebp
80104c7d:	89 e5                	mov    %esp,%ebp
80104c7f:	53                   	push   %ebx
80104c80:	83 ec 18             	sub    $0x18,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80104c83:	6a 08                	push   $0x8
80104c85:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104c88:	50                   	push   %eax
80104c89:	6a 00                	push   $0x0
80104c8b:	e8 14 f3 ff ff       	call   80103fa4 <argptr>
80104c90:	83 c4 10             	add    $0x10,%esp
80104c93:	85 c0                	test   %eax,%eax
80104c95:	78 79                	js     80104d10 <sys_pipe+0x94>
    return -1;
  if(pipealloc(&rf, &wf) < 0)
80104c97:	83 ec 08             	sub    $0x8,%esp
80104c9a:	8d 45 ec             	lea    -0x14(%ebp),%eax
80104c9d:	50                   	push   %eax
80104c9e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80104ca1:	50                   	push   %eax
80104ca2:	e8 60 e0 ff ff       	call   80102d07 <pipealloc>
80104ca7:	83 c4 10             	add    $0x10,%esp
80104caa:	85 c0                	test   %eax,%eax
80104cac:	78 69                	js     80104d17 <sys_pipe+0x9b>
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80104cae:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cb1:	e8 40 f4 ff ff       	call   801040f6 <fdalloc>
80104cb6:	89 c3                	mov    %eax,%ebx
80104cb8:	85 c0                	test   %eax,%eax
80104cba:	78 21                	js     80104cdd <sys_pipe+0x61>
80104cbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104cbf:	e8 32 f4 ff ff       	call   801040f6 <fdalloc>
80104cc4:	85 c0                	test   %eax,%eax
80104cc6:	78 15                	js     80104cdd <sys_pipe+0x61>
      myproc()->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  fd[0] = fd0;
80104cc8:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ccb:	89 1a                	mov    %ebx,(%edx)
  fd[1] = fd1;
80104ccd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104cd0:	89 42 04             	mov    %eax,0x4(%edx)
  return 0;
80104cd3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104cd8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104cdb:	c9                   	leave  
80104cdc:	c3                   	ret    
    if(fd0 >= 0)
80104cdd:	85 db                	test   %ebx,%ebx
80104cdf:	79 20                	jns    80104d01 <sys_pipe+0x85>
    fileclose(rf);
80104ce1:	83 ec 0c             	sub    $0xc,%esp
80104ce4:	ff 75 f0             	push   -0x10(%ebp)
80104ce7:	e8 d7 bf ff ff       	call   80100cc3 <fileclose>
    fileclose(wf);
80104cec:	83 c4 04             	add    $0x4,%esp
80104cef:	ff 75 ec             	push   -0x14(%ebp)
80104cf2:	e8 cc bf ff ff       	call   80100cc3 <fileclose>
    return -1;
80104cf7:	83 c4 10             	add    $0x10,%esp
80104cfa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cff:	eb d7                	jmp    80104cd8 <sys_pipe+0x5c>
      myproc()->ofile[fd0] = 0;
80104d01:	e8 15 e5 ff ff       	call   8010321b <myproc>
80104d06:	c7 44 98 28 00 00 00 	movl   $0x0,0x28(%eax,%ebx,4)
80104d0d:	00 
80104d0e:	eb d1                	jmp    80104ce1 <sys_pipe+0x65>
    return -1;
80104d10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d15:	eb c1                	jmp    80104cd8 <sys_pipe+0x5c>
    return -1;
80104d17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d1c:	eb ba                	jmp    80104cd8 <sys_pipe+0x5c>

80104d1e <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80104d1e:	55                   	push   %ebp
80104d1f:	89 e5                	mov    %esp,%ebp
80104d21:	83 ec 08             	sub    $0x8,%esp
  return fork();
80104d24:	e8 68 e6 ff ff       	call   80103391 <fork>
}
80104d29:	c9                   	leave  
80104d2a:	c3                   	ret    

80104d2b <sys_exit>:

int
sys_exit(void)
{
80104d2b:	55                   	push   %ebp
80104d2c:	89 e5                	mov    %esp,%ebp
80104d2e:	83 ec 08             	sub    $0x8,%esp
  exit();
80104d31:	e8 4c e9 ff ff       	call   80103682 <exit>
  return 0;  // not reached
}
80104d36:	b8 00 00 00 00       	mov    $0x0,%eax
80104d3b:	c9                   	leave  
80104d3c:	c3                   	ret    

80104d3d <sys_wait>:

int
sys_wait(void)
{
80104d3d:	55                   	push   %ebp
80104d3e:	89 e5                	mov    %esp,%ebp
80104d40:	83 ec 08             	sub    $0x8,%esp
  return wait();
80104d43:	e8 c6 ea ff ff       	call   8010380e <wait>
}
80104d48:	c9                   	leave  
80104d49:	c3                   	ret    

80104d4a <sys_kill>:

int
sys_kill(void)
{
80104d4a:	55                   	push   %ebp
80104d4b:	89 e5                	mov    %esp,%ebp
80104d4d:	83 ec 20             	sub    $0x20,%esp
  int pid;

  if(argint(0, &pid) < 0)
80104d50:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d53:	50                   	push   %eax
80104d54:	6a 00                	push   $0x0
80104d56:	e8 21 f2 ff ff       	call   80103f7c <argint>
80104d5b:	83 c4 10             	add    $0x10,%esp
80104d5e:	85 c0                	test   %eax,%eax
80104d60:	78 10                	js     80104d72 <sys_kill+0x28>
    return -1;
  return kill(pid);
80104d62:	83 ec 0c             	sub    $0xc,%esp
80104d65:	ff 75 f4             	push   -0xc(%ebp)
80104d68:	e8 a1 eb ff ff       	call   8010390e <kill>
80104d6d:	83 c4 10             	add    $0x10,%esp
}
80104d70:	c9                   	leave  
80104d71:	c3                   	ret    
    return -1;
80104d72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104d77:	eb f7                	jmp    80104d70 <sys_kill+0x26>

80104d79 <sys_getpid>:

int
sys_getpid(void)
{
80104d79:	55                   	push   %ebp
80104d7a:	89 e5                	mov    %esp,%ebp
80104d7c:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80104d7f:	e8 97 e4 ff ff       	call   8010321b <myproc>
80104d84:	8b 40 10             	mov    0x10(%eax),%eax
}
80104d87:	c9                   	leave  
80104d88:	c3                   	ret    

80104d89 <sys_sbrk>:

int
sys_sbrk(void)
{
80104d89:	55                   	push   %ebp
80104d8a:	89 e5                	mov    %esp,%ebp
80104d8c:	53                   	push   %ebx
80104d8d:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80104d90:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104d93:	50                   	push   %eax
80104d94:	6a 00                	push   $0x0
80104d96:	e8 e1 f1 ff ff       	call   80103f7c <argint>
80104d9b:	83 c4 10             	add    $0x10,%esp
80104d9e:	85 c0                	test   %eax,%eax
80104da0:	78 20                	js     80104dc2 <sys_sbrk+0x39>
    return -1;
  addr = myproc()->sz;
80104da2:	e8 74 e4 ff ff       	call   8010321b <myproc>
80104da7:	8b 18                	mov    (%eax),%ebx
  if(growproc(n) < 0)
80104da9:	83 ec 0c             	sub    $0xc,%esp
80104dac:	ff 75 f4             	push   -0xc(%ebp)
80104daf:	e8 72 e5 ff ff       	call   80103326 <growproc>
80104db4:	83 c4 10             	add    $0x10,%esp
80104db7:	85 c0                	test   %eax,%eax
80104db9:	78 0e                	js     80104dc9 <sys_sbrk+0x40>
    return -1;
  return addr;
}
80104dbb:	89 d8                	mov    %ebx,%eax
80104dbd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104dc0:	c9                   	leave  
80104dc1:	c3                   	ret    
    return -1;
80104dc2:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104dc7:	eb f2                	jmp    80104dbb <sys_sbrk+0x32>
    return -1;
80104dc9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
80104dce:	eb eb                	jmp    80104dbb <sys_sbrk+0x32>

80104dd0 <sys_sleep>:

int
sys_sleep(void)
{
80104dd0:	55                   	push   %ebp
80104dd1:	89 e5                	mov    %esp,%ebp
80104dd3:	53                   	push   %ebx
80104dd4:	83 ec 1c             	sub    $0x1c,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80104dd7:	8d 45 f4             	lea    -0xc(%ebp),%eax
80104dda:	50                   	push   %eax
80104ddb:	6a 00                	push   $0x0
80104ddd:	e8 9a f1 ff ff       	call   80103f7c <argint>
80104de2:	83 c4 10             	add    $0x10,%esp
80104de5:	85 c0                	test   %eax,%eax
80104de7:	78 75                	js     80104e5e <sys_sleep+0x8e>
    return -1;
  acquire(&tickslock);
80104de9:	83 ec 0c             	sub    $0xc,%esp
80104dec:	68 a0 3e 11 80       	push   $0x80113ea0
80104df1:	e8 8a ee ff ff       	call   80103c80 <acquire>
  ticks0 = ticks;
80104df6:	8b 1d 80 3e 11 80    	mov    0x80113e80,%ebx
  while(ticks - ticks0 < n){
80104dfc:	83 c4 10             	add    $0x10,%esp
80104dff:	a1 80 3e 11 80       	mov    0x80113e80,%eax
80104e04:	29 d8                	sub    %ebx,%eax
80104e06:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80104e09:	73 39                	jae    80104e44 <sys_sleep+0x74>
    if(myproc()->killed){
80104e0b:	e8 0b e4 ff ff       	call   8010321b <myproc>
80104e10:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80104e14:	75 17                	jne    80104e2d <sys_sleep+0x5d>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
80104e16:	83 ec 08             	sub    $0x8,%esp
80104e19:	68 a0 3e 11 80       	push   $0x80113ea0
80104e1e:	68 80 3e 11 80       	push   $0x80113e80
80104e23:	e8 55 e9 ff ff       	call   8010377d <sleep>
80104e28:	83 c4 10             	add    $0x10,%esp
80104e2b:	eb d2                	jmp    80104dff <sys_sleep+0x2f>
      release(&tickslock);
80104e2d:	83 ec 0c             	sub    $0xc,%esp
80104e30:	68 a0 3e 11 80       	push   $0x80113ea0
80104e35:	e8 ab ee ff ff       	call   80103ce5 <release>
      return -1;
80104e3a:	83 c4 10             	add    $0x10,%esp
80104e3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e42:	eb 15                	jmp    80104e59 <sys_sleep+0x89>
  }
  release(&tickslock);
80104e44:	83 ec 0c             	sub    $0xc,%esp
80104e47:	68 a0 3e 11 80       	push   $0x80113ea0
80104e4c:	e8 94 ee ff ff       	call   80103ce5 <release>
  return 0;
80104e51:	83 c4 10             	add    $0x10,%esp
80104e54:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104e59:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e5c:	c9                   	leave  
80104e5d:	c3                   	ret    
    return -1;
80104e5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104e63:	eb f4                	jmp    80104e59 <sys_sleep+0x89>

80104e65 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80104e65:	55                   	push   %ebp
80104e66:	89 e5                	mov    %esp,%ebp
80104e68:	53                   	push   %ebx
80104e69:	83 ec 10             	sub    $0x10,%esp
  uint xticks;

  acquire(&tickslock);
80104e6c:	68 a0 3e 11 80       	push   $0x80113ea0
80104e71:	e8 0a ee ff ff       	call   80103c80 <acquire>
  xticks = ticks;
80104e76:	8b 1d 80 3e 11 80    	mov    0x80113e80,%ebx
  release(&tickslock);
80104e7c:	c7 04 24 a0 3e 11 80 	movl   $0x80113ea0,(%esp)
80104e83:	e8 5d ee ff ff       	call   80103ce5 <release>
  return xticks;
}
80104e88:	89 d8                	mov    %ebx,%eax
80104e8a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104e8d:	c9                   	leave  
80104e8e:	c3                   	ret    

80104e8f <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80104e8f:	1e                   	push   %ds
  pushl %es
80104e90:	06                   	push   %es
  pushl %fs
80104e91:	0f a0                	push   %fs
  pushl %gs
80104e93:	0f a8                	push   %gs
  pushal
80104e95:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
80104e96:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80104e9a:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80104e9c:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80104e9e:	54                   	push   %esp
  call trap
80104e9f:	e8 37 01 00 00       	call   80104fdb <trap>
  addl $4, %esp
80104ea4:	83 c4 04             	add    $0x4,%esp

80104ea7 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80104ea7:	61                   	popa   
  popl %gs
80104ea8:	0f a9                	pop    %gs
  popl %fs
80104eaa:	0f a1                	pop    %fs
  popl %es
80104eac:	07                   	pop    %es
  popl %ds
80104ead:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80104eae:	83 c4 08             	add    $0x8,%esp
  iret
80104eb1:	cf                   	iret   

80104eb2 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80104eb2:	55                   	push   %ebp
80104eb3:	89 e5                	mov    %esp,%ebp
80104eb5:	53                   	push   %ebx
80104eb6:	83 ec 04             	sub    $0x4,%esp
  int i;

  for(i = 0; i < 256; i++)
80104eb9:	b8 00 00 00 00       	mov    $0x0,%eax
80104ebe:	eb 76                	jmp    80104f36 <tvinit+0x84>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80104ec0:	8b 0c 85 08 a0 10 80 	mov    -0x7fef5ff8(,%eax,4),%ecx
80104ec7:	66 89 0c c5 e0 3e 11 	mov    %cx,-0x7feec120(,%eax,8)
80104ece:	80 
80104ecf:	66 c7 04 c5 e2 3e 11 	movw   $0x8,-0x7feec11e(,%eax,8)
80104ed6:	80 08 00 
80104ed9:	0f b6 14 c5 e4 3e 11 	movzbl -0x7feec11c(,%eax,8),%edx
80104ee0:	80 
80104ee1:	83 e2 e0             	and    $0xffffffe0,%edx
80104ee4:	88 14 c5 e4 3e 11 80 	mov    %dl,-0x7feec11c(,%eax,8)
80104eeb:	c6 04 c5 e4 3e 11 80 	movb   $0x0,-0x7feec11c(,%eax,8)
80104ef2:	00 
80104ef3:	0f b6 14 c5 e5 3e 11 	movzbl -0x7feec11b(,%eax,8),%edx
80104efa:	80 
80104efb:	83 e2 f0             	and    $0xfffffff0,%edx
80104efe:	83 ca 0e             	or     $0xe,%edx
80104f01:	88 14 c5 e5 3e 11 80 	mov    %dl,-0x7feec11b(,%eax,8)
80104f08:	89 d3                	mov    %edx,%ebx
80104f0a:	83 e3 ef             	and    $0xffffffef,%ebx
80104f0d:	88 1c c5 e5 3e 11 80 	mov    %bl,-0x7feec11b(,%eax,8)
80104f14:	83 e2 8f             	and    $0xffffff8f,%edx
80104f17:	88 14 c5 e5 3e 11 80 	mov    %dl,-0x7feec11b(,%eax,8)
80104f1e:	83 ca 80             	or     $0xffffff80,%edx
80104f21:	88 14 c5 e5 3e 11 80 	mov    %dl,-0x7feec11b(,%eax,8)
80104f28:	c1 e9 10             	shr    $0x10,%ecx
80104f2b:	66 89 0c c5 e6 3e 11 	mov    %cx,-0x7feec11a(,%eax,8)
80104f32:	80 
  for(i = 0; i < 256; i++)
80104f33:	83 c0 01             	add    $0x1,%eax
80104f36:	3d ff 00 00 00       	cmp    $0xff,%eax
80104f3b:	7e 83                	jle    80104ec0 <tvinit+0xe>
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80104f3d:	8b 15 08 a1 10 80    	mov    0x8010a108,%edx
80104f43:	66 89 15 e0 40 11 80 	mov    %dx,0x801140e0
80104f4a:	66 c7 05 e2 40 11 80 	movw   $0x8,0x801140e2
80104f51:	08 00 
80104f53:	0f b6 05 e4 40 11 80 	movzbl 0x801140e4,%eax
80104f5a:	83 e0 e0             	and    $0xffffffe0,%eax
80104f5d:	a2 e4 40 11 80       	mov    %al,0x801140e4
80104f62:	c6 05 e4 40 11 80 00 	movb   $0x0,0x801140e4
80104f69:	0f b6 05 e5 40 11 80 	movzbl 0x801140e5,%eax
80104f70:	83 c8 0f             	or     $0xf,%eax
80104f73:	a2 e5 40 11 80       	mov    %al,0x801140e5
80104f78:	83 e0 ef             	and    $0xffffffef,%eax
80104f7b:	a2 e5 40 11 80       	mov    %al,0x801140e5
80104f80:	89 c1                	mov    %eax,%ecx
80104f82:	83 c9 60             	or     $0x60,%ecx
80104f85:	88 0d e5 40 11 80    	mov    %cl,0x801140e5
80104f8b:	83 c8 e0             	or     $0xffffffe0,%eax
80104f8e:	a2 e5 40 11 80       	mov    %al,0x801140e5
80104f93:	c1 ea 10             	shr    $0x10,%edx
80104f96:	66 89 15 e6 40 11 80 	mov    %dx,0x801140e6

  initlock(&tickslock, "time");
80104f9d:	83 ec 08             	sub    $0x8,%esp
80104fa0:	68 e9 6f 10 80       	push   $0x80106fe9
80104fa5:	68 a0 3e 11 80       	push   $0x80113ea0
80104faa:	e8 95 eb ff ff       	call   80103b44 <initlock>
}
80104faf:	83 c4 10             	add    $0x10,%esp
80104fb2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fb5:	c9                   	leave  
80104fb6:	c3                   	ret    

80104fb7 <idtinit>:

void
idtinit(void)
{
80104fb7:	55                   	push   %ebp
80104fb8:	89 e5                	mov    %esp,%ebp
80104fba:	83 ec 10             	sub    $0x10,%esp
  pd[0] = size-1;
80104fbd:	66 c7 45 fa ff 07    	movw   $0x7ff,-0x6(%ebp)
  pd[1] = (uint)p;
80104fc3:	b8 e0 3e 11 80       	mov    $0x80113ee0,%eax
80104fc8:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80104fcc:	c1 e8 10             	shr    $0x10,%eax
80104fcf:	66 89 45 fe          	mov    %ax,-0x2(%ebp)
  asm volatile("lidt (%0)" : : "r" (pd));
80104fd3:	8d 45 fa             	lea    -0x6(%ebp),%eax
80104fd6:	0f 01 18             	lidtl  (%eax)
  lidt(idt, sizeof(idt));
}
80104fd9:	c9                   	leave  
80104fda:	c3                   	ret    

80104fdb <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80104fdb:	55                   	push   %ebp
80104fdc:	89 e5                	mov    %esp,%ebp
80104fde:	57                   	push   %edi
80104fdf:	56                   	push   %esi
80104fe0:	53                   	push   %ebx
80104fe1:	83 ec 1c             	sub    $0x1c,%esp
80104fe4:	8b 5d 08             	mov    0x8(%ebp),%ebx
  if(tf->trapno == T_SYSCALL){
80104fe7:	8b 43 30             	mov    0x30(%ebx),%eax
80104fea:	83 f8 40             	cmp    $0x40,%eax
80104fed:	74 13                	je     80105002 <trap+0x27>
    if(myproc()->killed)
      exit();
    return;
  }

  switch(tf->trapno){
80104fef:	83 e8 20             	sub    $0x20,%eax
80104ff2:	83 f8 1f             	cmp    $0x1f,%eax
80104ff5:	0f 87 3a 01 00 00    	ja     80105135 <trap+0x15a>
80104ffb:	ff 24 85 90 70 10 80 	jmp    *-0x7fef8f70(,%eax,4)
    if(myproc()->killed)
80105002:	e8 14 e2 ff ff       	call   8010321b <myproc>
80105007:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
8010500b:	75 1f                	jne    8010502c <trap+0x51>
    myproc()->tf = tf;
8010500d:	e8 09 e2 ff ff       	call   8010321b <myproc>
80105012:	89 58 18             	mov    %ebx,0x18(%eax)
    syscall();
80105015:	e8 25 f0 ff ff       	call   8010403f <syscall>
    if(myproc()->killed)
8010501a:	e8 fc e1 ff ff       	call   8010321b <myproc>
8010501f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105023:	74 7e                	je     801050a3 <trap+0xc8>
      exit();
80105025:	e8 58 e6 ff ff       	call   80103682 <exit>
    return;
8010502a:	eb 77                	jmp    801050a3 <trap+0xc8>
      exit();
8010502c:	e8 51 e6 ff ff       	call   80103682 <exit>
80105031:	eb da                	jmp    8010500d <trap+0x32>
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
80105033:	e8 c8 e1 ff ff       	call   80103200 <cpuid>
80105038:	85 c0                	test   %eax,%eax
8010503a:	74 6f                	je     801050ab <trap+0xd0>
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    lapiceoi();
8010503c:	e8 35 d3 ff ff       	call   80102376 <lapiceoi>
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80105041:	e8 d5 e1 ff ff       	call   8010321b <myproc>
80105046:	85 c0                	test   %eax,%eax
80105048:	74 1c                	je     80105066 <trap+0x8b>
8010504a:	e8 cc e1 ff ff       	call   8010321b <myproc>
8010504f:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105053:	74 11                	je     80105066 <trap+0x8b>
80105055:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105059:	83 e0 03             	and    $0x3,%eax
8010505c:	66 83 f8 03          	cmp    $0x3,%ax
80105060:	0f 84 62 01 00 00    	je     801051c8 <trap+0x1ed>
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80105066:	e8 b0 e1 ff ff       	call   8010321b <myproc>
8010506b:	85 c0                	test   %eax,%eax
8010506d:	74 0f                	je     8010507e <trap+0xa3>
8010506f:	e8 a7 e1 ff ff       	call   8010321b <myproc>
80105074:	83 78 0c 04          	cmpl   $0x4,0xc(%eax)
80105078:	0f 84 54 01 00 00    	je     801051d2 <trap+0x1f7>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
8010507e:	e8 98 e1 ff ff       	call   8010321b <myproc>
80105083:	85 c0                	test   %eax,%eax
80105085:	74 1c                	je     801050a3 <trap+0xc8>
80105087:	e8 8f e1 ff ff       	call   8010321b <myproc>
8010508c:	83 78 24 00          	cmpl   $0x0,0x24(%eax)
80105090:	74 11                	je     801050a3 <trap+0xc8>
80105092:	0f b7 43 3c          	movzwl 0x3c(%ebx),%eax
80105096:	83 e0 03             	and    $0x3,%eax
80105099:	66 83 f8 03          	cmp    $0x3,%ax
8010509d:	0f 84 43 01 00 00    	je     801051e6 <trap+0x20b>
    exit();
}
801050a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
801050a6:	5b                   	pop    %ebx
801050a7:	5e                   	pop    %esi
801050a8:	5f                   	pop    %edi
801050a9:	5d                   	pop    %ebp
801050aa:	c3                   	ret    
      acquire(&tickslock);
801050ab:	83 ec 0c             	sub    $0xc,%esp
801050ae:	68 a0 3e 11 80       	push   $0x80113ea0
801050b3:	e8 c8 eb ff ff       	call   80103c80 <acquire>
      ticks++;
801050b8:	83 05 80 3e 11 80 01 	addl   $0x1,0x80113e80
      wakeup(&ticks);
801050bf:	c7 04 24 80 3e 11 80 	movl   $0x80113e80,(%esp)
801050c6:	e8 1a e8 ff ff       	call   801038e5 <wakeup>
      release(&tickslock);
801050cb:	c7 04 24 a0 3e 11 80 	movl   $0x80113ea0,(%esp)
801050d2:	e8 0e ec ff ff       	call   80103ce5 <release>
801050d7:	83 c4 10             	add    $0x10,%esp
801050da:	e9 5d ff ff ff       	jmp    8010503c <trap+0x61>
    ideintr();
801050df:	e8 78 cc ff ff       	call   80101d5c <ideintr>
    lapiceoi();
801050e4:	e8 8d d2 ff ff       	call   80102376 <lapiceoi>
    break;
801050e9:	e9 53 ff ff ff       	jmp    80105041 <trap+0x66>
    kbdintr();
801050ee:	e8 cd d0 ff ff       	call   801021c0 <kbdintr>
    lapiceoi();
801050f3:	e8 7e d2 ff ff       	call   80102376 <lapiceoi>
    break;
801050f8:	e9 44 ff ff ff       	jmp    80105041 <trap+0x66>
    uartintr();
801050fd:	e8 fe 01 00 00       	call   80105300 <uartintr>
    lapiceoi();
80105102:	e8 6f d2 ff ff       	call   80102376 <lapiceoi>
    break;
80105107:	e9 35 ff ff ff       	jmp    80105041 <trap+0x66>
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010510c:	8b 7b 38             	mov    0x38(%ebx),%edi
            cpuid(), tf->cs, tf->eip);
8010510f:	0f b7 73 3c          	movzwl 0x3c(%ebx),%esi
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80105113:	e8 e8 e0 ff ff       	call   80103200 <cpuid>
80105118:	57                   	push   %edi
80105119:	0f b7 f6             	movzwl %si,%esi
8010511c:	56                   	push   %esi
8010511d:	50                   	push   %eax
8010511e:	68 f4 6f 10 80       	push   $0x80106ff4
80105123:	e8 df b4 ff ff       	call   80100607 <cprintf>
    lapiceoi();
80105128:	e8 49 d2 ff ff       	call   80102376 <lapiceoi>
    break;
8010512d:	83 c4 10             	add    $0x10,%esp
80105130:	e9 0c ff ff ff       	jmp    80105041 <trap+0x66>
    if(myproc() == 0 || (tf->cs&3) == 0){
80105135:	e8 e1 e0 ff ff       	call   8010321b <myproc>
8010513a:	85 c0                	test   %eax,%eax
8010513c:	74 5f                	je     8010519d <trap+0x1c2>
8010513e:	f6 43 3c 03          	testb  $0x3,0x3c(%ebx)
80105142:	74 59                	je     8010519d <trap+0x1c2>

static inline uint
rcr2(void)
{
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80105144:	0f 20 d7             	mov    %cr2,%edi
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80105147:	8b 43 38             	mov    0x38(%ebx),%eax
8010514a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010514d:	e8 ae e0 ff ff       	call   80103200 <cpuid>
80105152:	89 45 e0             	mov    %eax,-0x20(%ebp)
80105155:	8b 53 34             	mov    0x34(%ebx),%edx
80105158:	89 55 dc             	mov    %edx,-0x24(%ebp)
8010515b:	8b 73 30             	mov    0x30(%ebx),%esi
            myproc()->pid, myproc()->name, tf->trapno,
8010515e:	e8 b8 e0 ff ff       	call   8010321b <myproc>
80105163:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105166:	89 4d d8             	mov    %ecx,-0x28(%ebp)
80105169:	e8 ad e0 ff ff       	call   8010321b <myproc>
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010516e:	57                   	push   %edi
8010516f:	ff 75 e4             	push   -0x1c(%ebp)
80105172:	ff 75 e0             	push   -0x20(%ebp)
80105175:	ff 75 dc             	push   -0x24(%ebp)
80105178:	56                   	push   %esi
80105179:	ff 75 d8             	push   -0x28(%ebp)
8010517c:	ff 70 10             	push   0x10(%eax)
8010517f:	68 4c 70 10 80       	push   $0x8010704c
80105184:	e8 7e b4 ff ff       	call   80100607 <cprintf>
    myproc()->killed = 1;
80105189:	83 c4 20             	add    $0x20,%esp
8010518c:	e8 8a e0 ff ff       	call   8010321b <myproc>
80105191:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80105198:	e9 a4 fe ff ff       	jmp    80105041 <trap+0x66>
8010519d:	0f 20 d7             	mov    %cr2,%edi
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801051a0:	8b 73 38             	mov    0x38(%ebx),%esi
801051a3:	e8 58 e0 ff ff       	call   80103200 <cpuid>
801051a8:	83 ec 0c             	sub    $0xc,%esp
801051ab:	57                   	push   %edi
801051ac:	56                   	push   %esi
801051ad:	50                   	push   %eax
801051ae:	ff 73 30             	push   0x30(%ebx)
801051b1:	68 18 70 10 80       	push   $0x80107018
801051b6:	e8 4c b4 ff ff       	call   80100607 <cprintf>
      panic("trap");
801051bb:	83 c4 14             	add    $0x14,%esp
801051be:	68 ee 6f 10 80       	push   $0x80106fee
801051c3:	e8 80 b1 ff ff       	call   80100348 <panic>
    exit();
801051c8:	e8 b5 e4 ff ff       	call   80103682 <exit>
801051cd:	e9 94 fe ff ff       	jmp    80105066 <trap+0x8b>
  if(myproc() && myproc()->state == RUNNING &&
801051d2:	83 7b 30 20          	cmpl   $0x20,0x30(%ebx)
801051d6:	0f 85 a2 fe ff ff    	jne    8010507e <trap+0xa3>
    yield();
801051dc:	e8 6a e5 ff ff       	call   8010374b <yield>
801051e1:	e9 98 fe ff ff       	jmp    8010507e <trap+0xa3>
    exit();
801051e6:	e8 97 e4 ff ff       	call   80103682 <exit>
801051eb:	e9 b3 fe ff ff       	jmp    801050a3 <trap+0xc8>

801051f0 <uartgetc>:
}

static int
uartgetc(void)
{
  if(!uart)
801051f0:	83 3d e0 46 11 80 00 	cmpl   $0x0,0x801146e0
801051f7:	74 14                	je     8010520d <uartgetc+0x1d>
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801051f9:	ba fd 03 00 00       	mov    $0x3fd,%edx
801051fe:	ec                   	in     (%dx),%al
    return -1;
  if(!(inb(COM1+5) & 0x01))
801051ff:	a8 01                	test   $0x1,%al
80105201:	74 10                	je     80105213 <uartgetc+0x23>
80105203:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105208:	ec                   	in     (%dx),%al
    return -1;
  return inb(COM1+0);
80105209:	0f b6 c0             	movzbl %al,%eax
8010520c:	c3                   	ret    
    return -1;
8010520d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105212:	c3                   	ret    
    return -1;
80105213:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105218:	c3                   	ret    

80105219 <uartputc>:
  if(!uart)
80105219:	83 3d e0 46 11 80 00 	cmpl   $0x0,0x801146e0
80105220:	74 3b                	je     8010525d <uartputc+0x44>
{
80105222:	55                   	push   %ebp
80105223:	89 e5                	mov    %esp,%ebp
80105225:	53                   	push   %ebx
80105226:	83 ec 04             	sub    $0x4,%esp
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80105229:	bb 00 00 00 00       	mov    $0x0,%ebx
8010522e:	eb 10                	jmp    80105240 <uartputc+0x27>
    microdelay(10);
80105230:	83 ec 0c             	sub    $0xc,%esp
80105233:	6a 0a                	push   $0xa
80105235:	e8 5d d1 ff ff       	call   80102397 <microdelay>
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
8010523a:	83 c3 01             	add    $0x1,%ebx
8010523d:	83 c4 10             	add    $0x10,%esp
80105240:	83 fb 7f             	cmp    $0x7f,%ebx
80105243:	7f 0a                	jg     8010524f <uartputc+0x36>
80105245:	ba fd 03 00 00       	mov    $0x3fd,%edx
8010524a:	ec                   	in     (%dx),%al
8010524b:	a8 20                	test   $0x20,%al
8010524d:	74 e1                	je     80105230 <uartputc+0x17>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010524f:	8b 45 08             	mov    0x8(%ebp),%eax
80105252:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105257:	ee                   	out    %al,(%dx)
}
80105258:	8b 5d fc             	mov    -0x4(%ebp),%ebx
8010525b:	c9                   	leave  
8010525c:	c3                   	ret    
8010525d:	c3                   	ret    

8010525e <uartinit>:
{
8010525e:	55                   	push   %ebp
8010525f:	89 e5                	mov    %esp,%ebp
80105261:	56                   	push   %esi
80105262:	53                   	push   %ebx
80105263:	b9 00 00 00 00       	mov    $0x0,%ecx
80105268:	ba fa 03 00 00       	mov    $0x3fa,%edx
8010526d:	89 c8                	mov    %ecx,%eax
8010526f:	ee                   	out    %al,(%dx)
80105270:	be fb 03 00 00       	mov    $0x3fb,%esi
80105275:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
8010527a:	89 f2                	mov    %esi,%edx
8010527c:	ee                   	out    %al,(%dx)
8010527d:	b8 0c 00 00 00       	mov    $0xc,%eax
80105282:	ba f8 03 00 00       	mov    $0x3f8,%edx
80105287:	ee                   	out    %al,(%dx)
80105288:	bb f9 03 00 00       	mov    $0x3f9,%ebx
8010528d:	89 c8                	mov    %ecx,%eax
8010528f:	89 da                	mov    %ebx,%edx
80105291:	ee                   	out    %al,(%dx)
80105292:	b8 03 00 00 00       	mov    $0x3,%eax
80105297:	89 f2                	mov    %esi,%edx
80105299:	ee                   	out    %al,(%dx)
8010529a:	ba fc 03 00 00       	mov    $0x3fc,%edx
8010529f:	89 c8                	mov    %ecx,%eax
801052a1:	ee                   	out    %al,(%dx)
801052a2:	b8 01 00 00 00       	mov    $0x1,%eax
801052a7:	89 da                	mov    %ebx,%edx
801052a9:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801052aa:	ba fd 03 00 00       	mov    $0x3fd,%edx
801052af:	ec                   	in     (%dx),%al
  if(inb(COM1+5) == 0xFF)
801052b0:	3c ff                	cmp    $0xff,%al
801052b2:	74 45                	je     801052f9 <uartinit+0x9b>
  uart = 1;
801052b4:	c7 05 e0 46 11 80 01 	movl   $0x1,0x801146e0
801052bb:	00 00 00 
801052be:	ba fa 03 00 00       	mov    $0x3fa,%edx
801052c3:	ec                   	in     (%dx),%al
801052c4:	ba f8 03 00 00       	mov    $0x3f8,%edx
801052c9:	ec                   	in     (%dx),%al
  ioapicenable(IRQ_COM1, 0);
801052ca:	83 ec 08             	sub    $0x8,%esp
801052cd:	6a 00                	push   $0x0
801052cf:	6a 04                	push   $0x4
801052d1:	e8 8b cc ff ff       	call   80101f61 <ioapicenable>
  for(p="xv6...\n"; *p; p++)
801052d6:	83 c4 10             	add    $0x10,%esp
801052d9:	bb 10 71 10 80       	mov    $0x80107110,%ebx
801052de:	eb 12                	jmp    801052f2 <uartinit+0x94>
    uartputc(*p);
801052e0:	83 ec 0c             	sub    $0xc,%esp
801052e3:	0f be c0             	movsbl %al,%eax
801052e6:	50                   	push   %eax
801052e7:	e8 2d ff ff ff       	call   80105219 <uartputc>
  for(p="xv6...\n"; *p; p++)
801052ec:	83 c3 01             	add    $0x1,%ebx
801052ef:	83 c4 10             	add    $0x10,%esp
801052f2:	0f b6 03             	movzbl (%ebx),%eax
801052f5:	84 c0                	test   %al,%al
801052f7:	75 e7                	jne    801052e0 <uartinit+0x82>
}
801052f9:	8d 65 f8             	lea    -0x8(%ebp),%esp
801052fc:	5b                   	pop    %ebx
801052fd:	5e                   	pop    %esi
801052fe:	5d                   	pop    %ebp
801052ff:	c3                   	ret    

80105300 <uartintr>:

void
uartintr(void)
{
80105300:	55                   	push   %ebp
80105301:	89 e5                	mov    %esp,%ebp
80105303:	83 ec 14             	sub    $0x14,%esp
  consoleintr(uartgetc);
80105306:	68 f0 51 10 80       	push   $0x801051f0
8010530b:	e8 23 b4 ff ff       	call   80100733 <consoleintr>
}
80105310:	83 c4 10             	add    $0x10,%esp
80105313:	c9                   	leave  
80105314:	c3                   	ret    

80105315 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80105315:	6a 00                	push   $0x0
  pushl $0
80105317:	6a 00                	push   $0x0
  jmp alltraps
80105319:	e9 71 fb ff ff       	jmp    80104e8f <alltraps>

8010531e <vector1>:
.globl vector1
vector1:
  pushl $0
8010531e:	6a 00                	push   $0x0
  pushl $1
80105320:	6a 01                	push   $0x1
  jmp alltraps
80105322:	e9 68 fb ff ff       	jmp    80104e8f <alltraps>

80105327 <vector2>:
.globl vector2
vector2:
  pushl $0
80105327:	6a 00                	push   $0x0
  pushl $2
80105329:	6a 02                	push   $0x2
  jmp alltraps
8010532b:	e9 5f fb ff ff       	jmp    80104e8f <alltraps>

80105330 <vector3>:
.globl vector3
vector3:
  pushl $0
80105330:	6a 00                	push   $0x0
  pushl $3
80105332:	6a 03                	push   $0x3
  jmp alltraps
80105334:	e9 56 fb ff ff       	jmp    80104e8f <alltraps>

80105339 <vector4>:
.globl vector4
vector4:
  pushl $0
80105339:	6a 00                	push   $0x0
  pushl $4
8010533b:	6a 04                	push   $0x4
  jmp alltraps
8010533d:	e9 4d fb ff ff       	jmp    80104e8f <alltraps>

80105342 <vector5>:
.globl vector5
vector5:
  pushl $0
80105342:	6a 00                	push   $0x0
  pushl $5
80105344:	6a 05                	push   $0x5
  jmp alltraps
80105346:	e9 44 fb ff ff       	jmp    80104e8f <alltraps>

8010534b <vector6>:
.globl vector6
vector6:
  pushl $0
8010534b:	6a 00                	push   $0x0
  pushl $6
8010534d:	6a 06                	push   $0x6
  jmp alltraps
8010534f:	e9 3b fb ff ff       	jmp    80104e8f <alltraps>

80105354 <vector7>:
.globl vector7
vector7:
  pushl $0
80105354:	6a 00                	push   $0x0
  pushl $7
80105356:	6a 07                	push   $0x7
  jmp alltraps
80105358:	e9 32 fb ff ff       	jmp    80104e8f <alltraps>

8010535d <vector8>:
.globl vector8
vector8:
  pushl $8
8010535d:	6a 08                	push   $0x8
  jmp alltraps
8010535f:	e9 2b fb ff ff       	jmp    80104e8f <alltraps>

80105364 <vector9>:
.globl vector9
vector9:
  pushl $0
80105364:	6a 00                	push   $0x0
  pushl $9
80105366:	6a 09                	push   $0x9
  jmp alltraps
80105368:	e9 22 fb ff ff       	jmp    80104e8f <alltraps>

8010536d <vector10>:
.globl vector10
vector10:
  pushl $10
8010536d:	6a 0a                	push   $0xa
  jmp alltraps
8010536f:	e9 1b fb ff ff       	jmp    80104e8f <alltraps>

80105374 <vector11>:
.globl vector11
vector11:
  pushl $11
80105374:	6a 0b                	push   $0xb
  jmp alltraps
80105376:	e9 14 fb ff ff       	jmp    80104e8f <alltraps>

8010537b <vector12>:
.globl vector12
vector12:
  pushl $12
8010537b:	6a 0c                	push   $0xc
  jmp alltraps
8010537d:	e9 0d fb ff ff       	jmp    80104e8f <alltraps>

80105382 <vector13>:
.globl vector13
vector13:
  pushl $13
80105382:	6a 0d                	push   $0xd
  jmp alltraps
80105384:	e9 06 fb ff ff       	jmp    80104e8f <alltraps>

80105389 <vector14>:
.globl vector14
vector14:
  pushl $14
80105389:	6a 0e                	push   $0xe
  jmp alltraps
8010538b:	e9 ff fa ff ff       	jmp    80104e8f <alltraps>

80105390 <vector15>:
.globl vector15
vector15:
  pushl $0
80105390:	6a 00                	push   $0x0
  pushl $15
80105392:	6a 0f                	push   $0xf
  jmp alltraps
80105394:	e9 f6 fa ff ff       	jmp    80104e8f <alltraps>

80105399 <vector16>:
.globl vector16
vector16:
  pushl $0
80105399:	6a 00                	push   $0x0
  pushl $16
8010539b:	6a 10                	push   $0x10
  jmp alltraps
8010539d:	e9 ed fa ff ff       	jmp    80104e8f <alltraps>

801053a2 <vector17>:
.globl vector17
vector17:
  pushl $17
801053a2:	6a 11                	push   $0x11
  jmp alltraps
801053a4:	e9 e6 fa ff ff       	jmp    80104e8f <alltraps>

801053a9 <vector18>:
.globl vector18
vector18:
  pushl $0
801053a9:	6a 00                	push   $0x0
  pushl $18
801053ab:	6a 12                	push   $0x12
  jmp alltraps
801053ad:	e9 dd fa ff ff       	jmp    80104e8f <alltraps>

801053b2 <vector19>:
.globl vector19
vector19:
  pushl $0
801053b2:	6a 00                	push   $0x0
  pushl $19
801053b4:	6a 13                	push   $0x13
  jmp alltraps
801053b6:	e9 d4 fa ff ff       	jmp    80104e8f <alltraps>

801053bb <vector20>:
.globl vector20
vector20:
  pushl $0
801053bb:	6a 00                	push   $0x0
  pushl $20
801053bd:	6a 14                	push   $0x14
  jmp alltraps
801053bf:	e9 cb fa ff ff       	jmp    80104e8f <alltraps>

801053c4 <vector21>:
.globl vector21
vector21:
  pushl $0
801053c4:	6a 00                	push   $0x0
  pushl $21
801053c6:	6a 15                	push   $0x15
  jmp alltraps
801053c8:	e9 c2 fa ff ff       	jmp    80104e8f <alltraps>

801053cd <vector22>:
.globl vector22
vector22:
  pushl $0
801053cd:	6a 00                	push   $0x0
  pushl $22
801053cf:	6a 16                	push   $0x16
  jmp alltraps
801053d1:	e9 b9 fa ff ff       	jmp    80104e8f <alltraps>

801053d6 <vector23>:
.globl vector23
vector23:
  pushl $0
801053d6:	6a 00                	push   $0x0
  pushl $23
801053d8:	6a 17                	push   $0x17
  jmp alltraps
801053da:	e9 b0 fa ff ff       	jmp    80104e8f <alltraps>

801053df <vector24>:
.globl vector24
vector24:
  pushl $0
801053df:	6a 00                	push   $0x0
  pushl $24
801053e1:	6a 18                	push   $0x18
  jmp alltraps
801053e3:	e9 a7 fa ff ff       	jmp    80104e8f <alltraps>

801053e8 <vector25>:
.globl vector25
vector25:
  pushl $0
801053e8:	6a 00                	push   $0x0
  pushl $25
801053ea:	6a 19                	push   $0x19
  jmp alltraps
801053ec:	e9 9e fa ff ff       	jmp    80104e8f <alltraps>

801053f1 <vector26>:
.globl vector26
vector26:
  pushl $0
801053f1:	6a 00                	push   $0x0
  pushl $26
801053f3:	6a 1a                	push   $0x1a
  jmp alltraps
801053f5:	e9 95 fa ff ff       	jmp    80104e8f <alltraps>

801053fa <vector27>:
.globl vector27
vector27:
  pushl $0
801053fa:	6a 00                	push   $0x0
  pushl $27
801053fc:	6a 1b                	push   $0x1b
  jmp alltraps
801053fe:	e9 8c fa ff ff       	jmp    80104e8f <alltraps>

80105403 <vector28>:
.globl vector28
vector28:
  pushl $0
80105403:	6a 00                	push   $0x0
  pushl $28
80105405:	6a 1c                	push   $0x1c
  jmp alltraps
80105407:	e9 83 fa ff ff       	jmp    80104e8f <alltraps>

8010540c <vector29>:
.globl vector29
vector29:
  pushl $0
8010540c:	6a 00                	push   $0x0
  pushl $29
8010540e:	6a 1d                	push   $0x1d
  jmp alltraps
80105410:	e9 7a fa ff ff       	jmp    80104e8f <alltraps>

80105415 <vector30>:
.globl vector30
vector30:
  pushl $0
80105415:	6a 00                	push   $0x0
  pushl $30
80105417:	6a 1e                	push   $0x1e
  jmp alltraps
80105419:	e9 71 fa ff ff       	jmp    80104e8f <alltraps>

8010541e <vector31>:
.globl vector31
vector31:
  pushl $0
8010541e:	6a 00                	push   $0x0
  pushl $31
80105420:	6a 1f                	push   $0x1f
  jmp alltraps
80105422:	e9 68 fa ff ff       	jmp    80104e8f <alltraps>

80105427 <vector32>:
.globl vector32
vector32:
  pushl $0
80105427:	6a 00                	push   $0x0
  pushl $32
80105429:	6a 20                	push   $0x20
  jmp alltraps
8010542b:	e9 5f fa ff ff       	jmp    80104e8f <alltraps>

80105430 <vector33>:
.globl vector33
vector33:
  pushl $0
80105430:	6a 00                	push   $0x0
  pushl $33
80105432:	6a 21                	push   $0x21
  jmp alltraps
80105434:	e9 56 fa ff ff       	jmp    80104e8f <alltraps>

80105439 <vector34>:
.globl vector34
vector34:
  pushl $0
80105439:	6a 00                	push   $0x0
  pushl $34
8010543b:	6a 22                	push   $0x22
  jmp alltraps
8010543d:	e9 4d fa ff ff       	jmp    80104e8f <alltraps>

80105442 <vector35>:
.globl vector35
vector35:
  pushl $0
80105442:	6a 00                	push   $0x0
  pushl $35
80105444:	6a 23                	push   $0x23
  jmp alltraps
80105446:	e9 44 fa ff ff       	jmp    80104e8f <alltraps>

8010544b <vector36>:
.globl vector36
vector36:
  pushl $0
8010544b:	6a 00                	push   $0x0
  pushl $36
8010544d:	6a 24                	push   $0x24
  jmp alltraps
8010544f:	e9 3b fa ff ff       	jmp    80104e8f <alltraps>

80105454 <vector37>:
.globl vector37
vector37:
  pushl $0
80105454:	6a 00                	push   $0x0
  pushl $37
80105456:	6a 25                	push   $0x25
  jmp alltraps
80105458:	e9 32 fa ff ff       	jmp    80104e8f <alltraps>

8010545d <vector38>:
.globl vector38
vector38:
  pushl $0
8010545d:	6a 00                	push   $0x0
  pushl $38
8010545f:	6a 26                	push   $0x26
  jmp alltraps
80105461:	e9 29 fa ff ff       	jmp    80104e8f <alltraps>

80105466 <vector39>:
.globl vector39
vector39:
  pushl $0
80105466:	6a 00                	push   $0x0
  pushl $39
80105468:	6a 27                	push   $0x27
  jmp alltraps
8010546a:	e9 20 fa ff ff       	jmp    80104e8f <alltraps>

8010546f <vector40>:
.globl vector40
vector40:
  pushl $0
8010546f:	6a 00                	push   $0x0
  pushl $40
80105471:	6a 28                	push   $0x28
  jmp alltraps
80105473:	e9 17 fa ff ff       	jmp    80104e8f <alltraps>

80105478 <vector41>:
.globl vector41
vector41:
  pushl $0
80105478:	6a 00                	push   $0x0
  pushl $41
8010547a:	6a 29                	push   $0x29
  jmp alltraps
8010547c:	e9 0e fa ff ff       	jmp    80104e8f <alltraps>

80105481 <vector42>:
.globl vector42
vector42:
  pushl $0
80105481:	6a 00                	push   $0x0
  pushl $42
80105483:	6a 2a                	push   $0x2a
  jmp alltraps
80105485:	e9 05 fa ff ff       	jmp    80104e8f <alltraps>

8010548a <vector43>:
.globl vector43
vector43:
  pushl $0
8010548a:	6a 00                	push   $0x0
  pushl $43
8010548c:	6a 2b                	push   $0x2b
  jmp alltraps
8010548e:	e9 fc f9 ff ff       	jmp    80104e8f <alltraps>

80105493 <vector44>:
.globl vector44
vector44:
  pushl $0
80105493:	6a 00                	push   $0x0
  pushl $44
80105495:	6a 2c                	push   $0x2c
  jmp alltraps
80105497:	e9 f3 f9 ff ff       	jmp    80104e8f <alltraps>

8010549c <vector45>:
.globl vector45
vector45:
  pushl $0
8010549c:	6a 00                	push   $0x0
  pushl $45
8010549e:	6a 2d                	push   $0x2d
  jmp alltraps
801054a0:	e9 ea f9 ff ff       	jmp    80104e8f <alltraps>

801054a5 <vector46>:
.globl vector46
vector46:
  pushl $0
801054a5:	6a 00                	push   $0x0
  pushl $46
801054a7:	6a 2e                	push   $0x2e
  jmp alltraps
801054a9:	e9 e1 f9 ff ff       	jmp    80104e8f <alltraps>

801054ae <vector47>:
.globl vector47
vector47:
  pushl $0
801054ae:	6a 00                	push   $0x0
  pushl $47
801054b0:	6a 2f                	push   $0x2f
  jmp alltraps
801054b2:	e9 d8 f9 ff ff       	jmp    80104e8f <alltraps>

801054b7 <vector48>:
.globl vector48
vector48:
  pushl $0
801054b7:	6a 00                	push   $0x0
  pushl $48
801054b9:	6a 30                	push   $0x30
  jmp alltraps
801054bb:	e9 cf f9 ff ff       	jmp    80104e8f <alltraps>

801054c0 <vector49>:
.globl vector49
vector49:
  pushl $0
801054c0:	6a 00                	push   $0x0
  pushl $49
801054c2:	6a 31                	push   $0x31
  jmp alltraps
801054c4:	e9 c6 f9 ff ff       	jmp    80104e8f <alltraps>

801054c9 <vector50>:
.globl vector50
vector50:
  pushl $0
801054c9:	6a 00                	push   $0x0
  pushl $50
801054cb:	6a 32                	push   $0x32
  jmp alltraps
801054cd:	e9 bd f9 ff ff       	jmp    80104e8f <alltraps>

801054d2 <vector51>:
.globl vector51
vector51:
  pushl $0
801054d2:	6a 00                	push   $0x0
  pushl $51
801054d4:	6a 33                	push   $0x33
  jmp alltraps
801054d6:	e9 b4 f9 ff ff       	jmp    80104e8f <alltraps>

801054db <vector52>:
.globl vector52
vector52:
  pushl $0
801054db:	6a 00                	push   $0x0
  pushl $52
801054dd:	6a 34                	push   $0x34
  jmp alltraps
801054df:	e9 ab f9 ff ff       	jmp    80104e8f <alltraps>

801054e4 <vector53>:
.globl vector53
vector53:
  pushl $0
801054e4:	6a 00                	push   $0x0
  pushl $53
801054e6:	6a 35                	push   $0x35
  jmp alltraps
801054e8:	e9 a2 f9 ff ff       	jmp    80104e8f <alltraps>

801054ed <vector54>:
.globl vector54
vector54:
  pushl $0
801054ed:	6a 00                	push   $0x0
  pushl $54
801054ef:	6a 36                	push   $0x36
  jmp alltraps
801054f1:	e9 99 f9 ff ff       	jmp    80104e8f <alltraps>

801054f6 <vector55>:
.globl vector55
vector55:
  pushl $0
801054f6:	6a 00                	push   $0x0
  pushl $55
801054f8:	6a 37                	push   $0x37
  jmp alltraps
801054fa:	e9 90 f9 ff ff       	jmp    80104e8f <alltraps>

801054ff <vector56>:
.globl vector56
vector56:
  pushl $0
801054ff:	6a 00                	push   $0x0
  pushl $56
80105501:	6a 38                	push   $0x38
  jmp alltraps
80105503:	e9 87 f9 ff ff       	jmp    80104e8f <alltraps>

80105508 <vector57>:
.globl vector57
vector57:
  pushl $0
80105508:	6a 00                	push   $0x0
  pushl $57
8010550a:	6a 39                	push   $0x39
  jmp alltraps
8010550c:	e9 7e f9 ff ff       	jmp    80104e8f <alltraps>

80105511 <vector58>:
.globl vector58
vector58:
  pushl $0
80105511:	6a 00                	push   $0x0
  pushl $58
80105513:	6a 3a                	push   $0x3a
  jmp alltraps
80105515:	e9 75 f9 ff ff       	jmp    80104e8f <alltraps>

8010551a <vector59>:
.globl vector59
vector59:
  pushl $0
8010551a:	6a 00                	push   $0x0
  pushl $59
8010551c:	6a 3b                	push   $0x3b
  jmp alltraps
8010551e:	e9 6c f9 ff ff       	jmp    80104e8f <alltraps>

80105523 <vector60>:
.globl vector60
vector60:
  pushl $0
80105523:	6a 00                	push   $0x0
  pushl $60
80105525:	6a 3c                	push   $0x3c
  jmp alltraps
80105527:	e9 63 f9 ff ff       	jmp    80104e8f <alltraps>

8010552c <vector61>:
.globl vector61
vector61:
  pushl $0
8010552c:	6a 00                	push   $0x0
  pushl $61
8010552e:	6a 3d                	push   $0x3d
  jmp alltraps
80105530:	e9 5a f9 ff ff       	jmp    80104e8f <alltraps>

80105535 <vector62>:
.globl vector62
vector62:
  pushl $0
80105535:	6a 00                	push   $0x0
  pushl $62
80105537:	6a 3e                	push   $0x3e
  jmp alltraps
80105539:	e9 51 f9 ff ff       	jmp    80104e8f <alltraps>

8010553e <vector63>:
.globl vector63
vector63:
  pushl $0
8010553e:	6a 00                	push   $0x0
  pushl $63
80105540:	6a 3f                	push   $0x3f
  jmp alltraps
80105542:	e9 48 f9 ff ff       	jmp    80104e8f <alltraps>

80105547 <vector64>:
.globl vector64
vector64:
  pushl $0
80105547:	6a 00                	push   $0x0
  pushl $64
80105549:	6a 40                	push   $0x40
  jmp alltraps
8010554b:	e9 3f f9 ff ff       	jmp    80104e8f <alltraps>

80105550 <vector65>:
.globl vector65
vector65:
  pushl $0
80105550:	6a 00                	push   $0x0
  pushl $65
80105552:	6a 41                	push   $0x41
  jmp alltraps
80105554:	e9 36 f9 ff ff       	jmp    80104e8f <alltraps>

80105559 <vector66>:
.globl vector66
vector66:
  pushl $0
80105559:	6a 00                	push   $0x0
  pushl $66
8010555b:	6a 42                	push   $0x42
  jmp alltraps
8010555d:	e9 2d f9 ff ff       	jmp    80104e8f <alltraps>

80105562 <vector67>:
.globl vector67
vector67:
  pushl $0
80105562:	6a 00                	push   $0x0
  pushl $67
80105564:	6a 43                	push   $0x43
  jmp alltraps
80105566:	e9 24 f9 ff ff       	jmp    80104e8f <alltraps>

8010556b <vector68>:
.globl vector68
vector68:
  pushl $0
8010556b:	6a 00                	push   $0x0
  pushl $68
8010556d:	6a 44                	push   $0x44
  jmp alltraps
8010556f:	e9 1b f9 ff ff       	jmp    80104e8f <alltraps>

80105574 <vector69>:
.globl vector69
vector69:
  pushl $0
80105574:	6a 00                	push   $0x0
  pushl $69
80105576:	6a 45                	push   $0x45
  jmp alltraps
80105578:	e9 12 f9 ff ff       	jmp    80104e8f <alltraps>

8010557d <vector70>:
.globl vector70
vector70:
  pushl $0
8010557d:	6a 00                	push   $0x0
  pushl $70
8010557f:	6a 46                	push   $0x46
  jmp alltraps
80105581:	e9 09 f9 ff ff       	jmp    80104e8f <alltraps>

80105586 <vector71>:
.globl vector71
vector71:
  pushl $0
80105586:	6a 00                	push   $0x0
  pushl $71
80105588:	6a 47                	push   $0x47
  jmp alltraps
8010558a:	e9 00 f9 ff ff       	jmp    80104e8f <alltraps>

8010558f <vector72>:
.globl vector72
vector72:
  pushl $0
8010558f:	6a 00                	push   $0x0
  pushl $72
80105591:	6a 48                	push   $0x48
  jmp alltraps
80105593:	e9 f7 f8 ff ff       	jmp    80104e8f <alltraps>

80105598 <vector73>:
.globl vector73
vector73:
  pushl $0
80105598:	6a 00                	push   $0x0
  pushl $73
8010559a:	6a 49                	push   $0x49
  jmp alltraps
8010559c:	e9 ee f8 ff ff       	jmp    80104e8f <alltraps>

801055a1 <vector74>:
.globl vector74
vector74:
  pushl $0
801055a1:	6a 00                	push   $0x0
  pushl $74
801055a3:	6a 4a                	push   $0x4a
  jmp alltraps
801055a5:	e9 e5 f8 ff ff       	jmp    80104e8f <alltraps>

801055aa <vector75>:
.globl vector75
vector75:
  pushl $0
801055aa:	6a 00                	push   $0x0
  pushl $75
801055ac:	6a 4b                	push   $0x4b
  jmp alltraps
801055ae:	e9 dc f8 ff ff       	jmp    80104e8f <alltraps>

801055b3 <vector76>:
.globl vector76
vector76:
  pushl $0
801055b3:	6a 00                	push   $0x0
  pushl $76
801055b5:	6a 4c                	push   $0x4c
  jmp alltraps
801055b7:	e9 d3 f8 ff ff       	jmp    80104e8f <alltraps>

801055bc <vector77>:
.globl vector77
vector77:
  pushl $0
801055bc:	6a 00                	push   $0x0
  pushl $77
801055be:	6a 4d                	push   $0x4d
  jmp alltraps
801055c0:	e9 ca f8 ff ff       	jmp    80104e8f <alltraps>

801055c5 <vector78>:
.globl vector78
vector78:
  pushl $0
801055c5:	6a 00                	push   $0x0
  pushl $78
801055c7:	6a 4e                	push   $0x4e
  jmp alltraps
801055c9:	e9 c1 f8 ff ff       	jmp    80104e8f <alltraps>

801055ce <vector79>:
.globl vector79
vector79:
  pushl $0
801055ce:	6a 00                	push   $0x0
  pushl $79
801055d0:	6a 4f                	push   $0x4f
  jmp alltraps
801055d2:	e9 b8 f8 ff ff       	jmp    80104e8f <alltraps>

801055d7 <vector80>:
.globl vector80
vector80:
  pushl $0
801055d7:	6a 00                	push   $0x0
  pushl $80
801055d9:	6a 50                	push   $0x50
  jmp alltraps
801055db:	e9 af f8 ff ff       	jmp    80104e8f <alltraps>

801055e0 <vector81>:
.globl vector81
vector81:
  pushl $0
801055e0:	6a 00                	push   $0x0
  pushl $81
801055e2:	6a 51                	push   $0x51
  jmp alltraps
801055e4:	e9 a6 f8 ff ff       	jmp    80104e8f <alltraps>

801055e9 <vector82>:
.globl vector82
vector82:
  pushl $0
801055e9:	6a 00                	push   $0x0
  pushl $82
801055eb:	6a 52                	push   $0x52
  jmp alltraps
801055ed:	e9 9d f8 ff ff       	jmp    80104e8f <alltraps>

801055f2 <vector83>:
.globl vector83
vector83:
  pushl $0
801055f2:	6a 00                	push   $0x0
  pushl $83
801055f4:	6a 53                	push   $0x53
  jmp alltraps
801055f6:	e9 94 f8 ff ff       	jmp    80104e8f <alltraps>

801055fb <vector84>:
.globl vector84
vector84:
  pushl $0
801055fb:	6a 00                	push   $0x0
  pushl $84
801055fd:	6a 54                	push   $0x54
  jmp alltraps
801055ff:	e9 8b f8 ff ff       	jmp    80104e8f <alltraps>

80105604 <vector85>:
.globl vector85
vector85:
  pushl $0
80105604:	6a 00                	push   $0x0
  pushl $85
80105606:	6a 55                	push   $0x55
  jmp alltraps
80105608:	e9 82 f8 ff ff       	jmp    80104e8f <alltraps>

8010560d <vector86>:
.globl vector86
vector86:
  pushl $0
8010560d:	6a 00                	push   $0x0
  pushl $86
8010560f:	6a 56                	push   $0x56
  jmp alltraps
80105611:	e9 79 f8 ff ff       	jmp    80104e8f <alltraps>

80105616 <vector87>:
.globl vector87
vector87:
  pushl $0
80105616:	6a 00                	push   $0x0
  pushl $87
80105618:	6a 57                	push   $0x57
  jmp alltraps
8010561a:	e9 70 f8 ff ff       	jmp    80104e8f <alltraps>

8010561f <vector88>:
.globl vector88
vector88:
  pushl $0
8010561f:	6a 00                	push   $0x0
  pushl $88
80105621:	6a 58                	push   $0x58
  jmp alltraps
80105623:	e9 67 f8 ff ff       	jmp    80104e8f <alltraps>

80105628 <vector89>:
.globl vector89
vector89:
  pushl $0
80105628:	6a 00                	push   $0x0
  pushl $89
8010562a:	6a 59                	push   $0x59
  jmp alltraps
8010562c:	e9 5e f8 ff ff       	jmp    80104e8f <alltraps>

80105631 <vector90>:
.globl vector90
vector90:
  pushl $0
80105631:	6a 00                	push   $0x0
  pushl $90
80105633:	6a 5a                	push   $0x5a
  jmp alltraps
80105635:	e9 55 f8 ff ff       	jmp    80104e8f <alltraps>

8010563a <vector91>:
.globl vector91
vector91:
  pushl $0
8010563a:	6a 00                	push   $0x0
  pushl $91
8010563c:	6a 5b                	push   $0x5b
  jmp alltraps
8010563e:	e9 4c f8 ff ff       	jmp    80104e8f <alltraps>

80105643 <vector92>:
.globl vector92
vector92:
  pushl $0
80105643:	6a 00                	push   $0x0
  pushl $92
80105645:	6a 5c                	push   $0x5c
  jmp alltraps
80105647:	e9 43 f8 ff ff       	jmp    80104e8f <alltraps>

8010564c <vector93>:
.globl vector93
vector93:
  pushl $0
8010564c:	6a 00                	push   $0x0
  pushl $93
8010564e:	6a 5d                	push   $0x5d
  jmp alltraps
80105650:	e9 3a f8 ff ff       	jmp    80104e8f <alltraps>

80105655 <vector94>:
.globl vector94
vector94:
  pushl $0
80105655:	6a 00                	push   $0x0
  pushl $94
80105657:	6a 5e                	push   $0x5e
  jmp alltraps
80105659:	e9 31 f8 ff ff       	jmp    80104e8f <alltraps>

8010565e <vector95>:
.globl vector95
vector95:
  pushl $0
8010565e:	6a 00                	push   $0x0
  pushl $95
80105660:	6a 5f                	push   $0x5f
  jmp alltraps
80105662:	e9 28 f8 ff ff       	jmp    80104e8f <alltraps>

80105667 <vector96>:
.globl vector96
vector96:
  pushl $0
80105667:	6a 00                	push   $0x0
  pushl $96
80105669:	6a 60                	push   $0x60
  jmp alltraps
8010566b:	e9 1f f8 ff ff       	jmp    80104e8f <alltraps>

80105670 <vector97>:
.globl vector97
vector97:
  pushl $0
80105670:	6a 00                	push   $0x0
  pushl $97
80105672:	6a 61                	push   $0x61
  jmp alltraps
80105674:	e9 16 f8 ff ff       	jmp    80104e8f <alltraps>

80105679 <vector98>:
.globl vector98
vector98:
  pushl $0
80105679:	6a 00                	push   $0x0
  pushl $98
8010567b:	6a 62                	push   $0x62
  jmp alltraps
8010567d:	e9 0d f8 ff ff       	jmp    80104e8f <alltraps>

80105682 <vector99>:
.globl vector99
vector99:
  pushl $0
80105682:	6a 00                	push   $0x0
  pushl $99
80105684:	6a 63                	push   $0x63
  jmp alltraps
80105686:	e9 04 f8 ff ff       	jmp    80104e8f <alltraps>

8010568b <vector100>:
.globl vector100
vector100:
  pushl $0
8010568b:	6a 00                	push   $0x0
  pushl $100
8010568d:	6a 64                	push   $0x64
  jmp alltraps
8010568f:	e9 fb f7 ff ff       	jmp    80104e8f <alltraps>

80105694 <vector101>:
.globl vector101
vector101:
  pushl $0
80105694:	6a 00                	push   $0x0
  pushl $101
80105696:	6a 65                	push   $0x65
  jmp alltraps
80105698:	e9 f2 f7 ff ff       	jmp    80104e8f <alltraps>

8010569d <vector102>:
.globl vector102
vector102:
  pushl $0
8010569d:	6a 00                	push   $0x0
  pushl $102
8010569f:	6a 66                	push   $0x66
  jmp alltraps
801056a1:	e9 e9 f7 ff ff       	jmp    80104e8f <alltraps>

801056a6 <vector103>:
.globl vector103
vector103:
  pushl $0
801056a6:	6a 00                	push   $0x0
  pushl $103
801056a8:	6a 67                	push   $0x67
  jmp alltraps
801056aa:	e9 e0 f7 ff ff       	jmp    80104e8f <alltraps>

801056af <vector104>:
.globl vector104
vector104:
  pushl $0
801056af:	6a 00                	push   $0x0
  pushl $104
801056b1:	6a 68                	push   $0x68
  jmp alltraps
801056b3:	e9 d7 f7 ff ff       	jmp    80104e8f <alltraps>

801056b8 <vector105>:
.globl vector105
vector105:
  pushl $0
801056b8:	6a 00                	push   $0x0
  pushl $105
801056ba:	6a 69                	push   $0x69
  jmp alltraps
801056bc:	e9 ce f7 ff ff       	jmp    80104e8f <alltraps>

801056c1 <vector106>:
.globl vector106
vector106:
  pushl $0
801056c1:	6a 00                	push   $0x0
  pushl $106
801056c3:	6a 6a                	push   $0x6a
  jmp alltraps
801056c5:	e9 c5 f7 ff ff       	jmp    80104e8f <alltraps>

801056ca <vector107>:
.globl vector107
vector107:
  pushl $0
801056ca:	6a 00                	push   $0x0
  pushl $107
801056cc:	6a 6b                	push   $0x6b
  jmp alltraps
801056ce:	e9 bc f7 ff ff       	jmp    80104e8f <alltraps>

801056d3 <vector108>:
.globl vector108
vector108:
  pushl $0
801056d3:	6a 00                	push   $0x0
  pushl $108
801056d5:	6a 6c                	push   $0x6c
  jmp alltraps
801056d7:	e9 b3 f7 ff ff       	jmp    80104e8f <alltraps>

801056dc <vector109>:
.globl vector109
vector109:
  pushl $0
801056dc:	6a 00                	push   $0x0
  pushl $109
801056de:	6a 6d                	push   $0x6d
  jmp alltraps
801056e0:	e9 aa f7 ff ff       	jmp    80104e8f <alltraps>

801056e5 <vector110>:
.globl vector110
vector110:
  pushl $0
801056e5:	6a 00                	push   $0x0
  pushl $110
801056e7:	6a 6e                	push   $0x6e
  jmp alltraps
801056e9:	e9 a1 f7 ff ff       	jmp    80104e8f <alltraps>

801056ee <vector111>:
.globl vector111
vector111:
  pushl $0
801056ee:	6a 00                	push   $0x0
  pushl $111
801056f0:	6a 6f                	push   $0x6f
  jmp alltraps
801056f2:	e9 98 f7 ff ff       	jmp    80104e8f <alltraps>

801056f7 <vector112>:
.globl vector112
vector112:
  pushl $0
801056f7:	6a 00                	push   $0x0
  pushl $112
801056f9:	6a 70                	push   $0x70
  jmp alltraps
801056fb:	e9 8f f7 ff ff       	jmp    80104e8f <alltraps>

80105700 <vector113>:
.globl vector113
vector113:
  pushl $0
80105700:	6a 00                	push   $0x0
  pushl $113
80105702:	6a 71                	push   $0x71
  jmp alltraps
80105704:	e9 86 f7 ff ff       	jmp    80104e8f <alltraps>

80105709 <vector114>:
.globl vector114
vector114:
  pushl $0
80105709:	6a 00                	push   $0x0
  pushl $114
8010570b:	6a 72                	push   $0x72
  jmp alltraps
8010570d:	e9 7d f7 ff ff       	jmp    80104e8f <alltraps>

80105712 <vector115>:
.globl vector115
vector115:
  pushl $0
80105712:	6a 00                	push   $0x0
  pushl $115
80105714:	6a 73                	push   $0x73
  jmp alltraps
80105716:	e9 74 f7 ff ff       	jmp    80104e8f <alltraps>

8010571b <vector116>:
.globl vector116
vector116:
  pushl $0
8010571b:	6a 00                	push   $0x0
  pushl $116
8010571d:	6a 74                	push   $0x74
  jmp alltraps
8010571f:	e9 6b f7 ff ff       	jmp    80104e8f <alltraps>

80105724 <vector117>:
.globl vector117
vector117:
  pushl $0
80105724:	6a 00                	push   $0x0
  pushl $117
80105726:	6a 75                	push   $0x75
  jmp alltraps
80105728:	e9 62 f7 ff ff       	jmp    80104e8f <alltraps>

8010572d <vector118>:
.globl vector118
vector118:
  pushl $0
8010572d:	6a 00                	push   $0x0
  pushl $118
8010572f:	6a 76                	push   $0x76
  jmp alltraps
80105731:	e9 59 f7 ff ff       	jmp    80104e8f <alltraps>

80105736 <vector119>:
.globl vector119
vector119:
  pushl $0
80105736:	6a 00                	push   $0x0
  pushl $119
80105738:	6a 77                	push   $0x77
  jmp alltraps
8010573a:	e9 50 f7 ff ff       	jmp    80104e8f <alltraps>

8010573f <vector120>:
.globl vector120
vector120:
  pushl $0
8010573f:	6a 00                	push   $0x0
  pushl $120
80105741:	6a 78                	push   $0x78
  jmp alltraps
80105743:	e9 47 f7 ff ff       	jmp    80104e8f <alltraps>

80105748 <vector121>:
.globl vector121
vector121:
  pushl $0
80105748:	6a 00                	push   $0x0
  pushl $121
8010574a:	6a 79                	push   $0x79
  jmp alltraps
8010574c:	e9 3e f7 ff ff       	jmp    80104e8f <alltraps>

80105751 <vector122>:
.globl vector122
vector122:
  pushl $0
80105751:	6a 00                	push   $0x0
  pushl $122
80105753:	6a 7a                	push   $0x7a
  jmp alltraps
80105755:	e9 35 f7 ff ff       	jmp    80104e8f <alltraps>

8010575a <vector123>:
.globl vector123
vector123:
  pushl $0
8010575a:	6a 00                	push   $0x0
  pushl $123
8010575c:	6a 7b                	push   $0x7b
  jmp alltraps
8010575e:	e9 2c f7 ff ff       	jmp    80104e8f <alltraps>

80105763 <vector124>:
.globl vector124
vector124:
  pushl $0
80105763:	6a 00                	push   $0x0
  pushl $124
80105765:	6a 7c                	push   $0x7c
  jmp alltraps
80105767:	e9 23 f7 ff ff       	jmp    80104e8f <alltraps>

8010576c <vector125>:
.globl vector125
vector125:
  pushl $0
8010576c:	6a 00                	push   $0x0
  pushl $125
8010576e:	6a 7d                	push   $0x7d
  jmp alltraps
80105770:	e9 1a f7 ff ff       	jmp    80104e8f <alltraps>

80105775 <vector126>:
.globl vector126
vector126:
  pushl $0
80105775:	6a 00                	push   $0x0
  pushl $126
80105777:	6a 7e                	push   $0x7e
  jmp alltraps
80105779:	e9 11 f7 ff ff       	jmp    80104e8f <alltraps>

8010577e <vector127>:
.globl vector127
vector127:
  pushl $0
8010577e:	6a 00                	push   $0x0
  pushl $127
80105780:	6a 7f                	push   $0x7f
  jmp alltraps
80105782:	e9 08 f7 ff ff       	jmp    80104e8f <alltraps>

80105787 <vector128>:
.globl vector128
vector128:
  pushl $0
80105787:	6a 00                	push   $0x0
  pushl $128
80105789:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010578e:	e9 fc f6 ff ff       	jmp    80104e8f <alltraps>

80105793 <vector129>:
.globl vector129
vector129:
  pushl $0
80105793:	6a 00                	push   $0x0
  pushl $129
80105795:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010579a:	e9 f0 f6 ff ff       	jmp    80104e8f <alltraps>

8010579f <vector130>:
.globl vector130
vector130:
  pushl $0
8010579f:	6a 00                	push   $0x0
  pushl $130
801057a1:	68 82 00 00 00       	push   $0x82
  jmp alltraps
801057a6:	e9 e4 f6 ff ff       	jmp    80104e8f <alltraps>

801057ab <vector131>:
.globl vector131
vector131:
  pushl $0
801057ab:	6a 00                	push   $0x0
  pushl $131
801057ad:	68 83 00 00 00       	push   $0x83
  jmp alltraps
801057b2:	e9 d8 f6 ff ff       	jmp    80104e8f <alltraps>

801057b7 <vector132>:
.globl vector132
vector132:
  pushl $0
801057b7:	6a 00                	push   $0x0
  pushl $132
801057b9:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801057be:	e9 cc f6 ff ff       	jmp    80104e8f <alltraps>

801057c3 <vector133>:
.globl vector133
vector133:
  pushl $0
801057c3:	6a 00                	push   $0x0
  pushl $133
801057c5:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801057ca:	e9 c0 f6 ff ff       	jmp    80104e8f <alltraps>

801057cf <vector134>:
.globl vector134
vector134:
  pushl $0
801057cf:	6a 00                	push   $0x0
  pushl $134
801057d1:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801057d6:	e9 b4 f6 ff ff       	jmp    80104e8f <alltraps>

801057db <vector135>:
.globl vector135
vector135:
  pushl $0
801057db:	6a 00                	push   $0x0
  pushl $135
801057dd:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801057e2:	e9 a8 f6 ff ff       	jmp    80104e8f <alltraps>

801057e7 <vector136>:
.globl vector136
vector136:
  pushl $0
801057e7:	6a 00                	push   $0x0
  pushl $136
801057e9:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801057ee:	e9 9c f6 ff ff       	jmp    80104e8f <alltraps>

801057f3 <vector137>:
.globl vector137
vector137:
  pushl $0
801057f3:	6a 00                	push   $0x0
  pushl $137
801057f5:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801057fa:	e9 90 f6 ff ff       	jmp    80104e8f <alltraps>

801057ff <vector138>:
.globl vector138
vector138:
  pushl $0
801057ff:	6a 00                	push   $0x0
  pushl $138
80105801:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80105806:	e9 84 f6 ff ff       	jmp    80104e8f <alltraps>

8010580b <vector139>:
.globl vector139
vector139:
  pushl $0
8010580b:	6a 00                	push   $0x0
  pushl $139
8010580d:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80105812:	e9 78 f6 ff ff       	jmp    80104e8f <alltraps>

80105817 <vector140>:
.globl vector140
vector140:
  pushl $0
80105817:	6a 00                	push   $0x0
  pushl $140
80105819:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010581e:	e9 6c f6 ff ff       	jmp    80104e8f <alltraps>

80105823 <vector141>:
.globl vector141
vector141:
  pushl $0
80105823:	6a 00                	push   $0x0
  pushl $141
80105825:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
8010582a:	e9 60 f6 ff ff       	jmp    80104e8f <alltraps>

8010582f <vector142>:
.globl vector142
vector142:
  pushl $0
8010582f:	6a 00                	push   $0x0
  pushl $142
80105831:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80105836:	e9 54 f6 ff ff       	jmp    80104e8f <alltraps>

8010583b <vector143>:
.globl vector143
vector143:
  pushl $0
8010583b:	6a 00                	push   $0x0
  pushl $143
8010583d:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80105842:	e9 48 f6 ff ff       	jmp    80104e8f <alltraps>

80105847 <vector144>:
.globl vector144
vector144:
  pushl $0
80105847:	6a 00                	push   $0x0
  pushl $144
80105849:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010584e:	e9 3c f6 ff ff       	jmp    80104e8f <alltraps>

80105853 <vector145>:
.globl vector145
vector145:
  pushl $0
80105853:	6a 00                	push   $0x0
  pushl $145
80105855:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010585a:	e9 30 f6 ff ff       	jmp    80104e8f <alltraps>

8010585f <vector146>:
.globl vector146
vector146:
  pushl $0
8010585f:	6a 00                	push   $0x0
  pushl $146
80105861:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80105866:	e9 24 f6 ff ff       	jmp    80104e8f <alltraps>

8010586b <vector147>:
.globl vector147
vector147:
  pushl $0
8010586b:	6a 00                	push   $0x0
  pushl $147
8010586d:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80105872:	e9 18 f6 ff ff       	jmp    80104e8f <alltraps>

80105877 <vector148>:
.globl vector148
vector148:
  pushl $0
80105877:	6a 00                	push   $0x0
  pushl $148
80105879:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010587e:	e9 0c f6 ff ff       	jmp    80104e8f <alltraps>

80105883 <vector149>:
.globl vector149
vector149:
  pushl $0
80105883:	6a 00                	push   $0x0
  pushl $149
80105885:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010588a:	e9 00 f6 ff ff       	jmp    80104e8f <alltraps>

8010588f <vector150>:
.globl vector150
vector150:
  pushl $0
8010588f:	6a 00                	push   $0x0
  pushl $150
80105891:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80105896:	e9 f4 f5 ff ff       	jmp    80104e8f <alltraps>

8010589b <vector151>:
.globl vector151
vector151:
  pushl $0
8010589b:	6a 00                	push   $0x0
  pushl $151
8010589d:	68 97 00 00 00       	push   $0x97
  jmp alltraps
801058a2:	e9 e8 f5 ff ff       	jmp    80104e8f <alltraps>

801058a7 <vector152>:
.globl vector152
vector152:
  pushl $0
801058a7:	6a 00                	push   $0x0
  pushl $152
801058a9:	68 98 00 00 00       	push   $0x98
  jmp alltraps
801058ae:	e9 dc f5 ff ff       	jmp    80104e8f <alltraps>

801058b3 <vector153>:
.globl vector153
vector153:
  pushl $0
801058b3:	6a 00                	push   $0x0
  pushl $153
801058b5:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801058ba:	e9 d0 f5 ff ff       	jmp    80104e8f <alltraps>

801058bf <vector154>:
.globl vector154
vector154:
  pushl $0
801058bf:	6a 00                	push   $0x0
  pushl $154
801058c1:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801058c6:	e9 c4 f5 ff ff       	jmp    80104e8f <alltraps>

801058cb <vector155>:
.globl vector155
vector155:
  pushl $0
801058cb:	6a 00                	push   $0x0
  pushl $155
801058cd:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801058d2:	e9 b8 f5 ff ff       	jmp    80104e8f <alltraps>

801058d7 <vector156>:
.globl vector156
vector156:
  pushl $0
801058d7:	6a 00                	push   $0x0
  pushl $156
801058d9:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801058de:	e9 ac f5 ff ff       	jmp    80104e8f <alltraps>

801058e3 <vector157>:
.globl vector157
vector157:
  pushl $0
801058e3:	6a 00                	push   $0x0
  pushl $157
801058e5:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801058ea:	e9 a0 f5 ff ff       	jmp    80104e8f <alltraps>

801058ef <vector158>:
.globl vector158
vector158:
  pushl $0
801058ef:	6a 00                	push   $0x0
  pushl $158
801058f1:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801058f6:	e9 94 f5 ff ff       	jmp    80104e8f <alltraps>

801058fb <vector159>:
.globl vector159
vector159:
  pushl $0
801058fb:	6a 00                	push   $0x0
  pushl $159
801058fd:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80105902:	e9 88 f5 ff ff       	jmp    80104e8f <alltraps>

80105907 <vector160>:
.globl vector160
vector160:
  pushl $0
80105907:	6a 00                	push   $0x0
  pushl $160
80105909:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
8010590e:	e9 7c f5 ff ff       	jmp    80104e8f <alltraps>

80105913 <vector161>:
.globl vector161
vector161:
  pushl $0
80105913:	6a 00                	push   $0x0
  pushl $161
80105915:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
8010591a:	e9 70 f5 ff ff       	jmp    80104e8f <alltraps>

8010591f <vector162>:
.globl vector162
vector162:
  pushl $0
8010591f:	6a 00                	push   $0x0
  pushl $162
80105921:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80105926:	e9 64 f5 ff ff       	jmp    80104e8f <alltraps>

8010592b <vector163>:
.globl vector163
vector163:
  pushl $0
8010592b:	6a 00                	push   $0x0
  pushl $163
8010592d:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80105932:	e9 58 f5 ff ff       	jmp    80104e8f <alltraps>

80105937 <vector164>:
.globl vector164
vector164:
  pushl $0
80105937:	6a 00                	push   $0x0
  pushl $164
80105939:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010593e:	e9 4c f5 ff ff       	jmp    80104e8f <alltraps>

80105943 <vector165>:
.globl vector165
vector165:
  pushl $0
80105943:	6a 00                	push   $0x0
  pushl $165
80105945:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010594a:	e9 40 f5 ff ff       	jmp    80104e8f <alltraps>

8010594f <vector166>:
.globl vector166
vector166:
  pushl $0
8010594f:	6a 00                	push   $0x0
  pushl $166
80105951:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80105956:	e9 34 f5 ff ff       	jmp    80104e8f <alltraps>

8010595b <vector167>:
.globl vector167
vector167:
  pushl $0
8010595b:	6a 00                	push   $0x0
  pushl $167
8010595d:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80105962:	e9 28 f5 ff ff       	jmp    80104e8f <alltraps>

80105967 <vector168>:
.globl vector168
vector168:
  pushl $0
80105967:	6a 00                	push   $0x0
  pushl $168
80105969:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010596e:	e9 1c f5 ff ff       	jmp    80104e8f <alltraps>

80105973 <vector169>:
.globl vector169
vector169:
  pushl $0
80105973:	6a 00                	push   $0x0
  pushl $169
80105975:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010597a:	e9 10 f5 ff ff       	jmp    80104e8f <alltraps>

8010597f <vector170>:
.globl vector170
vector170:
  pushl $0
8010597f:	6a 00                	push   $0x0
  pushl $170
80105981:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80105986:	e9 04 f5 ff ff       	jmp    80104e8f <alltraps>

8010598b <vector171>:
.globl vector171
vector171:
  pushl $0
8010598b:	6a 00                	push   $0x0
  pushl $171
8010598d:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80105992:	e9 f8 f4 ff ff       	jmp    80104e8f <alltraps>

80105997 <vector172>:
.globl vector172
vector172:
  pushl $0
80105997:	6a 00                	push   $0x0
  pushl $172
80105999:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010599e:	e9 ec f4 ff ff       	jmp    80104e8f <alltraps>

801059a3 <vector173>:
.globl vector173
vector173:
  pushl $0
801059a3:	6a 00                	push   $0x0
  pushl $173
801059a5:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
801059aa:	e9 e0 f4 ff ff       	jmp    80104e8f <alltraps>

801059af <vector174>:
.globl vector174
vector174:
  pushl $0
801059af:	6a 00                	push   $0x0
  pushl $174
801059b1:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801059b6:	e9 d4 f4 ff ff       	jmp    80104e8f <alltraps>

801059bb <vector175>:
.globl vector175
vector175:
  pushl $0
801059bb:	6a 00                	push   $0x0
  pushl $175
801059bd:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801059c2:	e9 c8 f4 ff ff       	jmp    80104e8f <alltraps>

801059c7 <vector176>:
.globl vector176
vector176:
  pushl $0
801059c7:	6a 00                	push   $0x0
  pushl $176
801059c9:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801059ce:	e9 bc f4 ff ff       	jmp    80104e8f <alltraps>

801059d3 <vector177>:
.globl vector177
vector177:
  pushl $0
801059d3:	6a 00                	push   $0x0
  pushl $177
801059d5:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801059da:	e9 b0 f4 ff ff       	jmp    80104e8f <alltraps>

801059df <vector178>:
.globl vector178
vector178:
  pushl $0
801059df:	6a 00                	push   $0x0
  pushl $178
801059e1:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801059e6:	e9 a4 f4 ff ff       	jmp    80104e8f <alltraps>

801059eb <vector179>:
.globl vector179
vector179:
  pushl $0
801059eb:	6a 00                	push   $0x0
  pushl $179
801059ed:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801059f2:	e9 98 f4 ff ff       	jmp    80104e8f <alltraps>

801059f7 <vector180>:
.globl vector180
vector180:
  pushl $0
801059f7:	6a 00                	push   $0x0
  pushl $180
801059f9:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801059fe:	e9 8c f4 ff ff       	jmp    80104e8f <alltraps>

80105a03 <vector181>:
.globl vector181
vector181:
  pushl $0
80105a03:	6a 00                	push   $0x0
  pushl $181
80105a05:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80105a0a:	e9 80 f4 ff ff       	jmp    80104e8f <alltraps>

80105a0f <vector182>:
.globl vector182
vector182:
  pushl $0
80105a0f:	6a 00                	push   $0x0
  pushl $182
80105a11:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80105a16:	e9 74 f4 ff ff       	jmp    80104e8f <alltraps>

80105a1b <vector183>:
.globl vector183
vector183:
  pushl $0
80105a1b:	6a 00                	push   $0x0
  pushl $183
80105a1d:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80105a22:	e9 68 f4 ff ff       	jmp    80104e8f <alltraps>

80105a27 <vector184>:
.globl vector184
vector184:
  pushl $0
80105a27:	6a 00                	push   $0x0
  pushl $184
80105a29:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80105a2e:	e9 5c f4 ff ff       	jmp    80104e8f <alltraps>

80105a33 <vector185>:
.globl vector185
vector185:
  pushl $0
80105a33:	6a 00                	push   $0x0
  pushl $185
80105a35:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80105a3a:	e9 50 f4 ff ff       	jmp    80104e8f <alltraps>

80105a3f <vector186>:
.globl vector186
vector186:
  pushl $0
80105a3f:	6a 00                	push   $0x0
  pushl $186
80105a41:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80105a46:	e9 44 f4 ff ff       	jmp    80104e8f <alltraps>

80105a4b <vector187>:
.globl vector187
vector187:
  pushl $0
80105a4b:	6a 00                	push   $0x0
  pushl $187
80105a4d:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80105a52:	e9 38 f4 ff ff       	jmp    80104e8f <alltraps>

80105a57 <vector188>:
.globl vector188
vector188:
  pushl $0
80105a57:	6a 00                	push   $0x0
  pushl $188
80105a59:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80105a5e:	e9 2c f4 ff ff       	jmp    80104e8f <alltraps>

80105a63 <vector189>:
.globl vector189
vector189:
  pushl $0
80105a63:	6a 00                	push   $0x0
  pushl $189
80105a65:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80105a6a:	e9 20 f4 ff ff       	jmp    80104e8f <alltraps>

80105a6f <vector190>:
.globl vector190
vector190:
  pushl $0
80105a6f:	6a 00                	push   $0x0
  pushl $190
80105a71:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80105a76:	e9 14 f4 ff ff       	jmp    80104e8f <alltraps>

80105a7b <vector191>:
.globl vector191
vector191:
  pushl $0
80105a7b:	6a 00                	push   $0x0
  pushl $191
80105a7d:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80105a82:	e9 08 f4 ff ff       	jmp    80104e8f <alltraps>

80105a87 <vector192>:
.globl vector192
vector192:
  pushl $0
80105a87:	6a 00                	push   $0x0
  pushl $192
80105a89:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80105a8e:	e9 fc f3 ff ff       	jmp    80104e8f <alltraps>

80105a93 <vector193>:
.globl vector193
vector193:
  pushl $0
80105a93:	6a 00                	push   $0x0
  pushl $193
80105a95:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80105a9a:	e9 f0 f3 ff ff       	jmp    80104e8f <alltraps>

80105a9f <vector194>:
.globl vector194
vector194:
  pushl $0
80105a9f:	6a 00                	push   $0x0
  pushl $194
80105aa1:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80105aa6:	e9 e4 f3 ff ff       	jmp    80104e8f <alltraps>

80105aab <vector195>:
.globl vector195
vector195:
  pushl $0
80105aab:	6a 00                	push   $0x0
  pushl $195
80105aad:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80105ab2:	e9 d8 f3 ff ff       	jmp    80104e8f <alltraps>

80105ab7 <vector196>:
.globl vector196
vector196:
  pushl $0
80105ab7:	6a 00                	push   $0x0
  pushl $196
80105ab9:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80105abe:	e9 cc f3 ff ff       	jmp    80104e8f <alltraps>

80105ac3 <vector197>:
.globl vector197
vector197:
  pushl $0
80105ac3:	6a 00                	push   $0x0
  pushl $197
80105ac5:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80105aca:	e9 c0 f3 ff ff       	jmp    80104e8f <alltraps>

80105acf <vector198>:
.globl vector198
vector198:
  pushl $0
80105acf:	6a 00                	push   $0x0
  pushl $198
80105ad1:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80105ad6:	e9 b4 f3 ff ff       	jmp    80104e8f <alltraps>

80105adb <vector199>:
.globl vector199
vector199:
  pushl $0
80105adb:	6a 00                	push   $0x0
  pushl $199
80105add:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80105ae2:	e9 a8 f3 ff ff       	jmp    80104e8f <alltraps>

80105ae7 <vector200>:
.globl vector200
vector200:
  pushl $0
80105ae7:	6a 00                	push   $0x0
  pushl $200
80105ae9:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80105aee:	e9 9c f3 ff ff       	jmp    80104e8f <alltraps>

80105af3 <vector201>:
.globl vector201
vector201:
  pushl $0
80105af3:	6a 00                	push   $0x0
  pushl $201
80105af5:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80105afa:	e9 90 f3 ff ff       	jmp    80104e8f <alltraps>

80105aff <vector202>:
.globl vector202
vector202:
  pushl $0
80105aff:	6a 00                	push   $0x0
  pushl $202
80105b01:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80105b06:	e9 84 f3 ff ff       	jmp    80104e8f <alltraps>

80105b0b <vector203>:
.globl vector203
vector203:
  pushl $0
80105b0b:	6a 00                	push   $0x0
  pushl $203
80105b0d:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80105b12:	e9 78 f3 ff ff       	jmp    80104e8f <alltraps>

80105b17 <vector204>:
.globl vector204
vector204:
  pushl $0
80105b17:	6a 00                	push   $0x0
  pushl $204
80105b19:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
80105b1e:	e9 6c f3 ff ff       	jmp    80104e8f <alltraps>

80105b23 <vector205>:
.globl vector205
vector205:
  pushl $0
80105b23:	6a 00                	push   $0x0
  pushl $205
80105b25:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80105b2a:	e9 60 f3 ff ff       	jmp    80104e8f <alltraps>

80105b2f <vector206>:
.globl vector206
vector206:
  pushl $0
80105b2f:	6a 00                	push   $0x0
  pushl $206
80105b31:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80105b36:	e9 54 f3 ff ff       	jmp    80104e8f <alltraps>

80105b3b <vector207>:
.globl vector207
vector207:
  pushl $0
80105b3b:	6a 00                	push   $0x0
  pushl $207
80105b3d:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80105b42:	e9 48 f3 ff ff       	jmp    80104e8f <alltraps>

80105b47 <vector208>:
.globl vector208
vector208:
  pushl $0
80105b47:	6a 00                	push   $0x0
  pushl $208
80105b49:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80105b4e:	e9 3c f3 ff ff       	jmp    80104e8f <alltraps>

80105b53 <vector209>:
.globl vector209
vector209:
  pushl $0
80105b53:	6a 00                	push   $0x0
  pushl $209
80105b55:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80105b5a:	e9 30 f3 ff ff       	jmp    80104e8f <alltraps>

80105b5f <vector210>:
.globl vector210
vector210:
  pushl $0
80105b5f:	6a 00                	push   $0x0
  pushl $210
80105b61:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80105b66:	e9 24 f3 ff ff       	jmp    80104e8f <alltraps>

80105b6b <vector211>:
.globl vector211
vector211:
  pushl $0
80105b6b:	6a 00                	push   $0x0
  pushl $211
80105b6d:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80105b72:	e9 18 f3 ff ff       	jmp    80104e8f <alltraps>

80105b77 <vector212>:
.globl vector212
vector212:
  pushl $0
80105b77:	6a 00                	push   $0x0
  pushl $212
80105b79:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80105b7e:	e9 0c f3 ff ff       	jmp    80104e8f <alltraps>

80105b83 <vector213>:
.globl vector213
vector213:
  pushl $0
80105b83:	6a 00                	push   $0x0
  pushl $213
80105b85:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80105b8a:	e9 00 f3 ff ff       	jmp    80104e8f <alltraps>

80105b8f <vector214>:
.globl vector214
vector214:
  pushl $0
80105b8f:	6a 00                	push   $0x0
  pushl $214
80105b91:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80105b96:	e9 f4 f2 ff ff       	jmp    80104e8f <alltraps>

80105b9b <vector215>:
.globl vector215
vector215:
  pushl $0
80105b9b:	6a 00                	push   $0x0
  pushl $215
80105b9d:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80105ba2:	e9 e8 f2 ff ff       	jmp    80104e8f <alltraps>

80105ba7 <vector216>:
.globl vector216
vector216:
  pushl $0
80105ba7:	6a 00                	push   $0x0
  pushl $216
80105ba9:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80105bae:	e9 dc f2 ff ff       	jmp    80104e8f <alltraps>

80105bb3 <vector217>:
.globl vector217
vector217:
  pushl $0
80105bb3:	6a 00                	push   $0x0
  pushl $217
80105bb5:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80105bba:	e9 d0 f2 ff ff       	jmp    80104e8f <alltraps>

80105bbf <vector218>:
.globl vector218
vector218:
  pushl $0
80105bbf:	6a 00                	push   $0x0
  pushl $218
80105bc1:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80105bc6:	e9 c4 f2 ff ff       	jmp    80104e8f <alltraps>

80105bcb <vector219>:
.globl vector219
vector219:
  pushl $0
80105bcb:	6a 00                	push   $0x0
  pushl $219
80105bcd:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80105bd2:	e9 b8 f2 ff ff       	jmp    80104e8f <alltraps>

80105bd7 <vector220>:
.globl vector220
vector220:
  pushl $0
80105bd7:	6a 00                	push   $0x0
  pushl $220
80105bd9:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80105bde:	e9 ac f2 ff ff       	jmp    80104e8f <alltraps>

80105be3 <vector221>:
.globl vector221
vector221:
  pushl $0
80105be3:	6a 00                	push   $0x0
  pushl $221
80105be5:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80105bea:	e9 a0 f2 ff ff       	jmp    80104e8f <alltraps>

80105bef <vector222>:
.globl vector222
vector222:
  pushl $0
80105bef:	6a 00                	push   $0x0
  pushl $222
80105bf1:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80105bf6:	e9 94 f2 ff ff       	jmp    80104e8f <alltraps>

80105bfb <vector223>:
.globl vector223
vector223:
  pushl $0
80105bfb:	6a 00                	push   $0x0
  pushl $223
80105bfd:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80105c02:	e9 88 f2 ff ff       	jmp    80104e8f <alltraps>

80105c07 <vector224>:
.globl vector224
vector224:
  pushl $0
80105c07:	6a 00                	push   $0x0
  pushl $224
80105c09:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
80105c0e:	e9 7c f2 ff ff       	jmp    80104e8f <alltraps>

80105c13 <vector225>:
.globl vector225
vector225:
  pushl $0
80105c13:	6a 00                	push   $0x0
  pushl $225
80105c15:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80105c1a:	e9 70 f2 ff ff       	jmp    80104e8f <alltraps>

80105c1f <vector226>:
.globl vector226
vector226:
  pushl $0
80105c1f:	6a 00                	push   $0x0
  pushl $226
80105c21:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80105c26:	e9 64 f2 ff ff       	jmp    80104e8f <alltraps>

80105c2b <vector227>:
.globl vector227
vector227:
  pushl $0
80105c2b:	6a 00                	push   $0x0
  pushl $227
80105c2d:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80105c32:	e9 58 f2 ff ff       	jmp    80104e8f <alltraps>

80105c37 <vector228>:
.globl vector228
vector228:
  pushl $0
80105c37:	6a 00                	push   $0x0
  pushl $228
80105c39:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80105c3e:	e9 4c f2 ff ff       	jmp    80104e8f <alltraps>

80105c43 <vector229>:
.globl vector229
vector229:
  pushl $0
80105c43:	6a 00                	push   $0x0
  pushl $229
80105c45:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80105c4a:	e9 40 f2 ff ff       	jmp    80104e8f <alltraps>

80105c4f <vector230>:
.globl vector230
vector230:
  pushl $0
80105c4f:	6a 00                	push   $0x0
  pushl $230
80105c51:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80105c56:	e9 34 f2 ff ff       	jmp    80104e8f <alltraps>

80105c5b <vector231>:
.globl vector231
vector231:
  pushl $0
80105c5b:	6a 00                	push   $0x0
  pushl $231
80105c5d:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80105c62:	e9 28 f2 ff ff       	jmp    80104e8f <alltraps>

80105c67 <vector232>:
.globl vector232
vector232:
  pushl $0
80105c67:	6a 00                	push   $0x0
  pushl $232
80105c69:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80105c6e:	e9 1c f2 ff ff       	jmp    80104e8f <alltraps>

80105c73 <vector233>:
.globl vector233
vector233:
  pushl $0
80105c73:	6a 00                	push   $0x0
  pushl $233
80105c75:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80105c7a:	e9 10 f2 ff ff       	jmp    80104e8f <alltraps>

80105c7f <vector234>:
.globl vector234
vector234:
  pushl $0
80105c7f:	6a 00                	push   $0x0
  pushl $234
80105c81:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80105c86:	e9 04 f2 ff ff       	jmp    80104e8f <alltraps>

80105c8b <vector235>:
.globl vector235
vector235:
  pushl $0
80105c8b:	6a 00                	push   $0x0
  pushl $235
80105c8d:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80105c92:	e9 f8 f1 ff ff       	jmp    80104e8f <alltraps>

80105c97 <vector236>:
.globl vector236
vector236:
  pushl $0
80105c97:	6a 00                	push   $0x0
  pushl $236
80105c99:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80105c9e:	e9 ec f1 ff ff       	jmp    80104e8f <alltraps>

80105ca3 <vector237>:
.globl vector237
vector237:
  pushl $0
80105ca3:	6a 00                	push   $0x0
  pushl $237
80105ca5:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80105caa:	e9 e0 f1 ff ff       	jmp    80104e8f <alltraps>

80105caf <vector238>:
.globl vector238
vector238:
  pushl $0
80105caf:	6a 00                	push   $0x0
  pushl $238
80105cb1:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80105cb6:	e9 d4 f1 ff ff       	jmp    80104e8f <alltraps>

80105cbb <vector239>:
.globl vector239
vector239:
  pushl $0
80105cbb:	6a 00                	push   $0x0
  pushl $239
80105cbd:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80105cc2:	e9 c8 f1 ff ff       	jmp    80104e8f <alltraps>

80105cc7 <vector240>:
.globl vector240
vector240:
  pushl $0
80105cc7:	6a 00                	push   $0x0
  pushl $240
80105cc9:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80105cce:	e9 bc f1 ff ff       	jmp    80104e8f <alltraps>

80105cd3 <vector241>:
.globl vector241
vector241:
  pushl $0
80105cd3:	6a 00                	push   $0x0
  pushl $241
80105cd5:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80105cda:	e9 b0 f1 ff ff       	jmp    80104e8f <alltraps>

80105cdf <vector242>:
.globl vector242
vector242:
  pushl $0
80105cdf:	6a 00                	push   $0x0
  pushl $242
80105ce1:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80105ce6:	e9 a4 f1 ff ff       	jmp    80104e8f <alltraps>

80105ceb <vector243>:
.globl vector243
vector243:
  pushl $0
80105ceb:	6a 00                	push   $0x0
  pushl $243
80105ced:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80105cf2:	e9 98 f1 ff ff       	jmp    80104e8f <alltraps>

80105cf7 <vector244>:
.globl vector244
vector244:
  pushl $0
80105cf7:	6a 00                	push   $0x0
  pushl $244
80105cf9:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80105cfe:	e9 8c f1 ff ff       	jmp    80104e8f <alltraps>

80105d03 <vector245>:
.globl vector245
vector245:
  pushl $0
80105d03:	6a 00                	push   $0x0
  pushl $245
80105d05:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80105d0a:	e9 80 f1 ff ff       	jmp    80104e8f <alltraps>

80105d0f <vector246>:
.globl vector246
vector246:
  pushl $0
80105d0f:	6a 00                	push   $0x0
  pushl $246
80105d11:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80105d16:	e9 74 f1 ff ff       	jmp    80104e8f <alltraps>

80105d1b <vector247>:
.globl vector247
vector247:
  pushl $0
80105d1b:	6a 00                	push   $0x0
  pushl $247
80105d1d:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80105d22:	e9 68 f1 ff ff       	jmp    80104e8f <alltraps>

80105d27 <vector248>:
.globl vector248
vector248:
  pushl $0
80105d27:	6a 00                	push   $0x0
  pushl $248
80105d29:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80105d2e:	e9 5c f1 ff ff       	jmp    80104e8f <alltraps>

80105d33 <vector249>:
.globl vector249
vector249:
  pushl $0
80105d33:	6a 00                	push   $0x0
  pushl $249
80105d35:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80105d3a:	e9 50 f1 ff ff       	jmp    80104e8f <alltraps>

80105d3f <vector250>:
.globl vector250
vector250:
  pushl $0
80105d3f:	6a 00                	push   $0x0
  pushl $250
80105d41:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80105d46:	e9 44 f1 ff ff       	jmp    80104e8f <alltraps>

80105d4b <vector251>:
.globl vector251
vector251:
  pushl $0
80105d4b:	6a 00                	push   $0x0
  pushl $251
80105d4d:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80105d52:	e9 38 f1 ff ff       	jmp    80104e8f <alltraps>

80105d57 <vector252>:
.globl vector252
vector252:
  pushl $0
80105d57:	6a 00                	push   $0x0
  pushl $252
80105d59:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80105d5e:	e9 2c f1 ff ff       	jmp    80104e8f <alltraps>

80105d63 <vector253>:
.globl vector253
vector253:
  pushl $0
80105d63:	6a 00                	push   $0x0
  pushl $253
80105d65:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80105d6a:	e9 20 f1 ff ff       	jmp    80104e8f <alltraps>

80105d6f <vector254>:
.globl vector254
vector254:
  pushl $0
80105d6f:	6a 00                	push   $0x0
  pushl $254
80105d71:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80105d76:	e9 14 f1 ff ff       	jmp    80104e8f <alltraps>

80105d7b <vector255>:
.globl vector255
vector255:
  pushl $0
80105d7b:	6a 00                	push   $0x0
  pushl $255
80105d7d:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80105d82:	e9 08 f1 ff ff       	jmp    80104e8f <alltraps>

80105d87 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80105d87:	55                   	push   %ebp
80105d88:	89 e5                	mov    %esp,%ebp
80105d8a:	57                   	push   %edi
80105d8b:	56                   	push   %esi
80105d8c:	53                   	push   %ebx
80105d8d:	83 ec 0c             	sub    $0xc,%esp
80105d90:	89 d3                	mov    %edx,%ebx
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80105d92:	c1 ea 16             	shr    $0x16,%edx
80105d95:	8d 3c 90             	lea    (%eax,%edx,4),%edi
  if(*pde & PTE_P){
80105d98:	8b 37                	mov    (%edi),%esi
80105d9a:	f7 c6 01 00 00 00    	test   $0x1,%esi
80105da0:	74 20                	je     80105dc2 <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80105da2:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
80105da8:	81 c6 00 00 00 80    	add    $0x80000000,%esi
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
  }
  return &pgtab[PTX(va)];
80105dae:	c1 eb 0c             	shr    $0xc,%ebx
80105db1:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
80105db7:	8d 04 9e             	lea    (%esi,%ebx,4),%eax
}
80105dba:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105dbd:	5b                   	pop    %ebx
80105dbe:	5e                   	pop    %esi
80105dbf:	5f                   	pop    %edi
80105dc0:	5d                   	pop    %ebp
80105dc1:	c3                   	ret    
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80105dc2:	85 c9                	test   %ecx,%ecx
80105dc4:	74 2b                	je     80105df1 <walkpgdir+0x6a>
80105dc6:	e8 d8 c2 ff ff       	call   801020a3 <kalloc>
80105dcb:	89 c6                	mov    %eax,%esi
80105dcd:	85 c0                	test   %eax,%eax
80105dcf:	74 20                	je     80105df1 <walkpgdir+0x6a>
    memset(pgtab, 0, PGSIZE);
80105dd1:	83 ec 04             	sub    $0x4,%esp
80105dd4:	68 00 10 00 00       	push   $0x1000
80105dd9:	6a 00                	push   $0x0
80105ddb:	50                   	push   %eax
80105ddc:	e8 4b df ff ff       	call   80103d2c <memset>
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80105de1:	8d 86 00 00 00 80    	lea    -0x80000000(%esi),%eax
80105de7:	83 c8 07             	or     $0x7,%eax
80105dea:	89 07                	mov    %eax,(%edi)
80105dec:	83 c4 10             	add    $0x10,%esp
80105def:	eb bd                	jmp    80105dae <walkpgdir+0x27>
      return 0;
80105df1:	b8 00 00 00 00       	mov    $0x0,%eax
80105df6:	eb c2                	jmp    80105dba <walkpgdir+0x33>

80105df8 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80105df8:	55                   	push   %ebp
80105df9:	89 e5                	mov    %esp,%ebp
80105dfb:	57                   	push   %edi
80105dfc:	56                   	push   %esi
80105dfd:	53                   	push   %ebx
80105dfe:	83 ec 1c             	sub    $0x1c,%esp
80105e01:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80105e04:	8b 75 08             	mov    0x8(%ebp),%esi
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80105e07:	89 d3                	mov    %edx,%ebx
80105e09:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80105e0f:	8d 7c 0a ff          	lea    -0x1(%edx,%ecx,1),%edi
80105e13:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e19:	b9 01 00 00 00       	mov    $0x1,%ecx
80105e1e:	89 da                	mov    %ebx,%edx
80105e20:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e23:	e8 5f ff ff ff       	call   80105d87 <walkpgdir>
80105e28:	85 c0                	test   %eax,%eax
80105e2a:	74 2e                	je     80105e5a <mappages+0x62>
      return -1;
    if(*pte & PTE_P)
80105e2c:	f6 00 01             	testb  $0x1,(%eax)
80105e2f:	75 1c                	jne    80105e4d <mappages+0x55>
      panic("remap");
    *pte = pa | perm | PTE_P;
80105e31:	89 f2                	mov    %esi,%edx
80105e33:	0b 55 0c             	or     0xc(%ebp),%edx
80105e36:	83 ca 01             	or     $0x1,%edx
80105e39:	89 10                	mov    %edx,(%eax)
    if(a == last)
80105e3b:	39 fb                	cmp    %edi,%ebx
80105e3d:	74 28                	je     80105e67 <mappages+0x6f>
      break;
    a += PGSIZE;
80105e3f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    pa += PGSIZE;
80105e45:	81 c6 00 10 00 00    	add    $0x1000,%esi
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80105e4b:	eb cc                	jmp    80105e19 <mappages+0x21>
      panic("remap");
80105e4d:	83 ec 0c             	sub    $0xc,%esp
80105e50:	68 18 71 10 80       	push   $0x80107118
80105e55:	e8 ee a4 ff ff       	call   80100348 <panic>
      return -1;
80105e5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  }
  return 0;
}
80105e5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
80105e62:	5b                   	pop    %ebx
80105e63:	5e                   	pop    %esi
80105e64:	5f                   	pop    %edi
80105e65:	5d                   	pop    %ebp
80105e66:	c3                   	ret    
  return 0;
80105e67:	b8 00 00 00 00       	mov    $0x0,%eax
80105e6c:	eb f1                	jmp    80105e5f <mappages+0x67>

80105e6e <seginit>:
{
80105e6e:	55                   	push   %ebp
80105e6f:	89 e5                	mov    %esp,%ebp
80105e71:	57                   	push   %edi
80105e72:	56                   	push   %esi
80105e73:	53                   	push   %ebx
80105e74:	83 ec 1c             	sub    $0x1c,%esp
  c = &cpus[cpuid()];
80105e77:	e8 84 d3 ff ff       	call   80103200 <cpuid>
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80105e7c:	69 f8 b0 00 00 00    	imul   $0xb0,%eax,%edi
80105e82:	66 c7 87 18 18 11 80 	movw   $0xffff,-0x7feee7e8(%edi)
80105e89:	ff ff 
80105e8b:	66 c7 87 1a 18 11 80 	movw   $0x0,-0x7feee7e6(%edi)
80105e92:	00 00 
80105e94:	c6 87 1c 18 11 80 00 	movb   $0x0,-0x7feee7e4(%edi)
80105e9b:	0f b6 8f 1d 18 11 80 	movzbl -0x7feee7e3(%edi),%ecx
80105ea2:	83 e1 f0             	and    $0xfffffff0,%ecx
80105ea5:	89 ce                	mov    %ecx,%esi
80105ea7:	83 ce 0a             	or     $0xa,%esi
80105eaa:	89 f2                	mov    %esi,%edx
80105eac:	88 97 1d 18 11 80    	mov    %dl,-0x7feee7e3(%edi)
80105eb2:	83 c9 1a             	or     $0x1a,%ecx
80105eb5:	88 8f 1d 18 11 80    	mov    %cl,-0x7feee7e3(%edi)
80105ebb:	83 e1 9f             	and    $0xffffff9f,%ecx
80105ebe:	88 8f 1d 18 11 80    	mov    %cl,-0x7feee7e3(%edi)
80105ec4:	83 c9 80             	or     $0xffffff80,%ecx
80105ec7:	88 8f 1d 18 11 80    	mov    %cl,-0x7feee7e3(%edi)
80105ecd:	0f b6 8f 1e 18 11 80 	movzbl -0x7feee7e2(%edi),%ecx
80105ed4:	83 c9 0f             	or     $0xf,%ecx
80105ed7:	88 8f 1e 18 11 80    	mov    %cl,-0x7feee7e2(%edi)
80105edd:	89 ce                	mov    %ecx,%esi
80105edf:	83 e6 ef             	and    $0xffffffef,%esi
80105ee2:	89 f2                	mov    %esi,%edx
80105ee4:	88 97 1e 18 11 80    	mov    %dl,-0x7feee7e2(%edi)
80105eea:	83 e1 cf             	and    $0xffffffcf,%ecx
80105eed:	88 8f 1e 18 11 80    	mov    %cl,-0x7feee7e2(%edi)
80105ef3:	89 ce                	mov    %ecx,%esi
80105ef5:	83 ce 40             	or     $0x40,%esi
80105ef8:	89 f2                	mov    %esi,%edx
80105efa:	88 97 1e 18 11 80    	mov    %dl,-0x7feee7e2(%edi)
80105f00:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f03:	88 8f 1e 18 11 80    	mov    %cl,-0x7feee7e2(%edi)
80105f09:	c6 87 1f 18 11 80 00 	movb   $0x0,-0x7feee7e1(%edi)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80105f10:	66 c7 87 20 18 11 80 	movw   $0xffff,-0x7feee7e0(%edi)
80105f17:	ff ff 
80105f19:	66 c7 87 22 18 11 80 	movw   $0x0,-0x7feee7de(%edi)
80105f20:	00 00 
80105f22:	c6 87 24 18 11 80 00 	movb   $0x0,-0x7feee7dc(%edi)
80105f29:	0f b6 8f 25 18 11 80 	movzbl -0x7feee7db(%edi),%ecx
80105f30:	83 e1 f0             	and    $0xfffffff0,%ecx
80105f33:	89 ce                	mov    %ecx,%esi
80105f35:	83 ce 02             	or     $0x2,%esi
80105f38:	89 f2                	mov    %esi,%edx
80105f3a:	88 97 25 18 11 80    	mov    %dl,-0x7feee7db(%edi)
80105f40:	83 c9 12             	or     $0x12,%ecx
80105f43:	88 8f 25 18 11 80    	mov    %cl,-0x7feee7db(%edi)
80105f49:	83 e1 9f             	and    $0xffffff9f,%ecx
80105f4c:	88 8f 25 18 11 80    	mov    %cl,-0x7feee7db(%edi)
80105f52:	83 c9 80             	or     $0xffffff80,%ecx
80105f55:	88 8f 25 18 11 80    	mov    %cl,-0x7feee7db(%edi)
80105f5b:	0f b6 8f 26 18 11 80 	movzbl -0x7feee7da(%edi),%ecx
80105f62:	83 c9 0f             	or     $0xf,%ecx
80105f65:	88 8f 26 18 11 80    	mov    %cl,-0x7feee7da(%edi)
80105f6b:	89 ce                	mov    %ecx,%esi
80105f6d:	83 e6 ef             	and    $0xffffffef,%esi
80105f70:	89 f2                	mov    %esi,%edx
80105f72:	88 97 26 18 11 80    	mov    %dl,-0x7feee7da(%edi)
80105f78:	83 e1 cf             	and    $0xffffffcf,%ecx
80105f7b:	88 8f 26 18 11 80    	mov    %cl,-0x7feee7da(%edi)
80105f81:	89 ce                	mov    %ecx,%esi
80105f83:	83 ce 40             	or     $0x40,%esi
80105f86:	89 f2                	mov    %esi,%edx
80105f88:	88 97 26 18 11 80    	mov    %dl,-0x7feee7da(%edi)
80105f8e:	83 c9 c0             	or     $0xffffffc0,%ecx
80105f91:	88 8f 26 18 11 80    	mov    %cl,-0x7feee7da(%edi)
80105f97:	c6 87 27 18 11 80 00 	movb   $0x0,-0x7feee7d9(%edi)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80105f9e:	66 c7 87 28 18 11 80 	movw   $0xffff,-0x7feee7d8(%edi)
80105fa5:	ff ff 
80105fa7:	66 c7 87 2a 18 11 80 	movw   $0x0,-0x7feee7d6(%edi)
80105fae:	00 00 
80105fb0:	c6 87 2c 18 11 80 00 	movb   $0x0,-0x7feee7d4(%edi)
80105fb7:	0f b6 9f 2d 18 11 80 	movzbl -0x7feee7d3(%edi),%ebx
80105fbe:	83 e3 f0             	and    $0xfffffff0,%ebx
80105fc1:	89 de                	mov    %ebx,%esi
80105fc3:	83 ce 0a             	or     $0xa,%esi
80105fc6:	89 f2                	mov    %esi,%edx
80105fc8:	88 97 2d 18 11 80    	mov    %dl,-0x7feee7d3(%edi)
80105fce:	89 de                	mov    %ebx,%esi
80105fd0:	83 ce 1a             	or     $0x1a,%esi
80105fd3:	89 f2                	mov    %esi,%edx
80105fd5:	88 97 2d 18 11 80    	mov    %dl,-0x7feee7d3(%edi)
80105fdb:	83 cb 7a             	or     $0x7a,%ebx
80105fde:	88 9f 2d 18 11 80    	mov    %bl,-0x7feee7d3(%edi)
80105fe4:	c6 87 2d 18 11 80 fa 	movb   $0xfa,-0x7feee7d3(%edi)
80105feb:	0f b6 9f 2e 18 11 80 	movzbl -0x7feee7d2(%edi),%ebx
80105ff2:	83 cb 0f             	or     $0xf,%ebx
80105ff5:	88 9f 2e 18 11 80    	mov    %bl,-0x7feee7d2(%edi)
80105ffb:	89 de                	mov    %ebx,%esi
80105ffd:	83 e6 ef             	and    $0xffffffef,%esi
80106000:	89 f2                	mov    %esi,%edx
80106002:	88 97 2e 18 11 80    	mov    %dl,-0x7feee7d2(%edi)
80106008:	83 e3 cf             	and    $0xffffffcf,%ebx
8010600b:	88 9f 2e 18 11 80    	mov    %bl,-0x7feee7d2(%edi)
80106011:	89 de                	mov    %ebx,%esi
80106013:	83 ce 40             	or     $0x40,%esi
80106016:	89 f2                	mov    %esi,%edx
80106018:	88 97 2e 18 11 80    	mov    %dl,-0x7feee7d2(%edi)
8010601e:	83 cb c0             	or     $0xffffffc0,%ebx
80106021:	88 9f 2e 18 11 80    	mov    %bl,-0x7feee7d2(%edi)
80106027:	c6 87 2f 18 11 80 00 	movb   $0x0,-0x7feee7d1(%edi)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
8010602e:	66 c7 87 30 18 11 80 	movw   $0xffff,-0x7feee7d0(%edi)
80106035:	ff ff 
80106037:	66 c7 87 32 18 11 80 	movw   $0x0,-0x7feee7ce(%edi)
8010603e:	00 00 
80106040:	c6 87 34 18 11 80 00 	movb   $0x0,-0x7feee7cc(%edi)
80106047:	0f b6 9f 35 18 11 80 	movzbl -0x7feee7cb(%edi),%ebx
8010604e:	83 e3 f0             	and    $0xfffffff0,%ebx
80106051:	89 de                	mov    %ebx,%esi
80106053:	83 ce 02             	or     $0x2,%esi
80106056:	89 f2                	mov    %esi,%edx
80106058:	88 97 35 18 11 80    	mov    %dl,-0x7feee7cb(%edi)
8010605e:	89 de                	mov    %ebx,%esi
80106060:	83 ce 12             	or     $0x12,%esi
80106063:	89 f2                	mov    %esi,%edx
80106065:	88 97 35 18 11 80    	mov    %dl,-0x7feee7cb(%edi)
8010606b:	83 cb 72             	or     $0x72,%ebx
8010606e:	88 9f 35 18 11 80    	mov    %bl,-0x7feee7cb(%edi)
80106074:	c6 87 35 18 11 80 f2 	movb   $0xf2,-0x7feee7cb(%edi)
8010607b:	0f b6 9f 36 18 11 80 	movzbl -0x7feee7ca(%edi),%ebx
80106082:	83 cb 0f             	or     $0xf,%ebx
80106085:	88 9f 36 18 11 80    	mov    %bl,-0x7feee7ca(%edi)
8010608b:	89 de                	mov    %ebx,%esi
8010608d:	83 e6 ef             	and    $0xffffffef,%esi
80106090:	89 f2                	mov    %esi,%edx
80106092:	88 97 36 18 11 80    	mov    %dl,-0x7feee7ca(%edi)
80106098:	83 e3 cf             	and    $0xffffffcf,%ebx
8010609b:	88 9f 36 18 11 80    	mov    %bl,-0x7feee7ca(%edi)
801060a1:	89 de                	mov    %ebx,%esi
801060a3:	83 ce 40             	or     $0x40,%esi
801060a6:	89 f2                	mov    %esi,%edx
801060a8:	88 97 36 18 11 80    	mov    %dl,-0x7feee7ca(%edi)
801060ae:	83 cb c0             	or     $0xffffffc0,%ebx
801060b1:	88 9f 36 18 11 80    	mov    %bl,-0x7feee7ca(%edi)
801060b7:	c6 87 37 18 11 80 00 	movb   $0x0,-0x7feee7c9(%edi)
  lgdt(c->gdt, sizeof(c->gdt));
801060be:	8d 97 10 18 11 80    	lea    -0x7feee7f0(%edi),%edx
  pd[0] = size-1;
801060c4:	66 c7 45 e2 2f 00    	movw   $0x2f,-0x1e(%ebp)
  pd[1] = (uint)p;
801060ca:	66 89 55 e4          	mov    %dx,-0x1c(%ebp)
  pd[2] = (uint)p >> 16;
801060ce:	c1 ea 10             	shr    $0x10,%edx
801060d1:	66 89 55 e6          	mov    %dx,-0x1a(%ebp)
  asm volatile("lgdt (%0)" : : "r" (pd));
801060d5:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801060d8:	0f 01 10             	lgdtl  (%eax)
}
801060db:	83 c4 1c             	add    $0x1c,%esp
801060de:	5b                   	pop    %ebx
801060df:	5e                   	pop    %esi
801060e0:	5f                   	pop    %edi
801060e1:	5d                   	pop    %ebp
801060e2:	c3                   	ret    

801060e3 <switchkvm>:
// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
  lcr3(V2P(kpgdir));   // switch to the kernel page table
801060e3:	a1 e4 46 11 80       	mov    0x801146e4,%eax
801060e8:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
801060ed:	0f 22 d8             	mov    %eax,%cr3
}
801060f0:	c3                   	ret    

801060f1 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
801060f1:	55                   	push   %ebp
801060f2:	89 e5                	mov    %esp,%ebp
801060f4:	57                   	push   %edi
801060f5:	56                   	push   %esi
801060f6:	53                   	push   %ebx
801060f7:	83 ec 1c             	sub    $0x1c,%esp
801060fa:	8b 75 08             	mov    0x8(%ebp),%esi
  if(p == 0)
801060fd:	85 f6                	test   %esi,%esi
801060ff:	0f 84 25 01 00 00    	je     8010622a <switchuvm+0x139>
    panic("switchuvm: no process");
  if(p->kstack == 0)
80106105:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
80106109:	0f 84 28 01 00 00    	je     80106237 <switchuvm+0x146>
    panic("switchuvm: no kstack");
  if(p->pgdir == 0)
8010610f:	83 7e 04 00          	cmpl   $0x0,0x4(%esi)
80106113:	0f 84 2b 01 00 00    	je     80106244 <switchuvm+0x153>
    panic("switchuvm: no pgdir");

  pushcli();
80106119:	e8 87 da ff ff       	call   80103ba5 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
8010611e:	e8 81 d0 ff ff       	call   801031a4 <mycpu>
80106123:	89 c3                	mov    %eax,%ebx
80106125:	e8 7a d0 ff ff       	call   801031a4 <mycpu>
8010612a:	8d 78 08             	lea    0x8(%eax),%edi
8010612d:	e8 72 d0 ff ff       	call   801031a4 <mycpu>
80106132:	83 c0 08             	add    $0x8,%eax
80106135:	c1 e8 10             	shr    $0x10,%eax
80106138:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010613b:	e8 64 d0 ff ff       	call   801031a4 <mycpu>
80106140:	83 c0 08             	add    $0x8,%eax
80106143:	c1 e8 18             	shr    $0x18,%eax
80106146:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
8010614d:	67 00 
8010614f:	66 89 bb 9a 00 00 00 	mov    %di,0x9a(%ebx)
80106156:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
8010615a:	88 8b 9c 00 00 00    	mov    %cl,0x9c(%ebx)
80106160:	0f b6 93 9d 00 00 00 	movzbl 0x9d(%ebx),%edx
80106167:	83 e2 f0             	and    $0xfffffff0,%edx
8010616a:	89 d1                	mov    %edx,%ecx
8010616c:	83 c9 09             	or     $0x9,%ecx
8010616f:	88 8b 9d 00 00 00    	mov    %cl,0x9d(%ebx)
80106175:	83 ca 19             	or     $0x19,%edx
80106178:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
8010617e:	83 e2 9f             	and    $0xffffff9f,%edx
80106181:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106187:	83 ca 80             	or     $0xffffff80,%edx
8010618a:	88 93 9d 00 00 00    	mov    %dl,0x9d(%ebx)
80106190:	0f b6 93 9e 00 00 00 	movzbl 0x9e(%ebx),%edx
80106197:	89 d1                	mov    %edx,%ecx
80106199:	83 e1 f0             	and    $0xfffffff0,%ecx
8010619c:	88 8b 9e 00 00 00    	mov    %cl,0x9e(%ebx)
801061a2:	89 d1                	mov    %edx,%ecx
801061a4:	83 e1 e0             	and    $0xffffffe0,%ecx
801061a7:	88 8b 9e 00 00 00    	mov    %cl,0x9e(%ebx)
801061ad:	83 e2 c0             	and    $0xffffffc0,%edx
801061b0:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
801061b6:	83 ca 40             	or     $0x40,%edx
801061b9:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
801061bf:	83 e2 7f             	and    $0x7f,%edx
801061c2:	88 93 9e 00 00 00    	mov    %dl,0x9e(%ebx)
801061c8:	88 83 9f 00 00 00    	mov    %al,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
801061ce:	e8 d1 cf ff ff       	call   801031a4 <mycpu>
801061d3:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801061da:	83 e2 ef             	and    $0xffffffef,%edx
801061dd:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
801061e3:	e8 bc cf ff ff       	call   801031a4 <mycpu>
801061e8:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
801061ee:	8b 5e 08             	mov    0x8(%esi),%ebx
801061f1:	e8 ae cf ff ff       	call   801031a4 <mycpu>
801061f6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
801061fc:	89 58 0c             	mov    %ebx,0xc(%eax)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
801061ff:	e8 a0 cf ff ff       	call   801031a4 <mycpu>
80106204:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  asm volatile("ltr %0" : : "r" (sel));
8010620a:	b8 28 00 00 00       	mov    $0x28,%eax
8010620f:	0f 00 d8             	ltr    %ax
  ltr(SEG_TSS << 3);
  lcr3(V2P(p->pgdir));  // switch to process's address space
80106212:	8b 46 04             	mov    0x4(%esi),%eax
80106215:	05 00 00 00 80       	add    $0x80000000,%eax
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010621a:	0f 22 d8             	mov    %eax,%cr3
  popcli();
8010621d:	e8 bf d9 ff ff       	call   80103be1 <popcli>
}
80106222:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106225:	5b                   	pop    %ebx
80106226:	5e                   	pop    %esi
80106227:	5f                   	pop    %edi
80106228:	5d                   	pop    %ebp
80106229:	c3                   	ret    
    panic("switchuvm: no process");
8010622a:	83 ec 0c             	sub    $0xc,%esp
8010622d:	68 1e 71 10 80       	push   $0x8010711e
80106232:	e8 11 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no kstack");
80106237:	83 ec 0c             	sub    $0xc,%esp
8010623a:	68 34 71 10 80       	push   $0x80107134
8010623f:	e8 04 a1 ff ff       	call   80100348 <panic>
    panic("switchuvm: no pgdir");
80106244:	83 ec 0c             	sub    $0xc,%esp
80106247:	68 49 71 10 80       	push   $0x80107149
8010624c:	e8 f7 a0 ff ff       	call   80100348 <panic>

80106251 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80106251:	55                   	push   %ebp
80106252:	89 e5                	mov    %esp,%ebp
80106254:	56                   	push   %esi
80106255:	53                   	push   %ebx
80106256:	8b 75 10             	mov    0x10(%ebp),%esi
  char *mem;

  if(sz >= PGSIZE)
80106259:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
8010625f:	77 4c                	ja     801062ad <inituvm+0x5c>
    panic("inituvm: more than a page");
  mem = kalloc();
80106261:	e8 3d be ff ff       	call   801020a3 <kalloc>
80106266:	89 c3                	mov    %eax,%ebx
  memset(mem, 0, PGSIZE);
80106268:	83 ec 04             	sub    $0x4,%esp
8010626b:	68 00 10 00 00       	push   $0x1000
80106270:	6a 00                	push   $0x0
80106272:	50                   	push   %eax
80106273:	e8 b4 da ff ff       	call   80103d2c <memset>
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80106278:	83 c4 08             	add    $0x8,%esp
8010627b:	6a 06                	push   $0x6
8010627d:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106283:	50                   	push   %eax
80106284:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106289:	ba 00 00 00 00       	mov    $0x0,%edx
8010628e:	8b 45 08             	mov    0x8(%ebp),%eax
80106291:	e8 62 fb ff ff       	call   80105df8 <mappages>
  memmove(mem, init, sz);
80106296:	83 c4 0c             	add    $0xc,%esp
80106299:	56                   	push   %esi
8010629a:	ff 75 0c             	push   0xc(%ebp)
8010629d:	53                   	push   %ebx
8010629e:	e8 01 db ff ff       	call   80103da4 <memmove>
}
801062a3:	83 c4 10             	add    $0x10,%esp
801062a6:	8d 65 f8             	lea    -0x8(%ebp),%esp
801062a9:	5b                   	pop    %ebx
801062aa:	5e                   	pop    %esi
801062ab:	5d                   	pop    %ebp
801062ac:	c3                   	ret    
    panic("inituvm: more than a page");
801062ad:	83 ec 0c             	sub    $0xc,%esp
801062b0:	68 5d 71 10 80       	push   $0x8010715d
801062b5:	e8 8e a0 ff ff       	call   80100348 <panic>

801062ba <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
801062ba:	55                   	push   %ebp
801062bb:	89 e5                	mov    %esp,%ebp
801062bd:	57                   	push   %edi
801062be:	56                   	push   %esi
801062bf:	53                   	push   %ebx
801062c0:	83 ec 0c             	sub    $0xc,%esp
801062c3:	8b 7d 18             	mov    0x18(%ebp),%edi
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
801062c6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801062c9:	81 e3 ff 0f 00 00    	and    $0xfff,%ebx
801062cf:	74 3c                	je     8010630d <loaduvm+0x53>
    panic("loaduvm: addr must be page aligned");
801062d1:	83 ec 0c             	sub    $0xc,%esp
801062d4:	68 18 72 10 80       	push   $0x80107218
801062d9:	e8 6a a0 ff ff       	call   80100348 <panic>
  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
      panic("loaduvm: address should exist");
801062de:	83 ec 0c             	sub    $0xc,%esp
801062e1:	68 77 71 10 80       	push   $0x80107177
801062e6:	e8 5d a0 ff ff       	call   80100348 <panic>
    pa = PTE_ADDR(*pte);
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
801062eb:	05 00 00 00 80       	add    $0x80000000,%eax
801062f0:	56                   	push   %esi
801062f1:	89 da                	mov    %ebx,%edx
801062f3:	03 55 14             	add    0x14(%ebp),%edx
801062f6:	52                   	push   %edx
801062f7:	50                   	push   %eax
801062f8:	ff 75 10             	push   0x10(%ebp)
801062fb:	e8 61 b4 ff ff       	call   80101761 <readi>
80106300:	83 c4 10             	add    $0x10,%esp
80106303:	39 f0                	cmp    %esi,%eax
80106305:	75 47                	jne    8010634e <loaduvm+0x94>
  for(i = 0; i < sz; i += PGSIZE){
80106307:	81 c3 00 10 00 00    	add    $0x1000,%ebx
8010630d:	39 fb                	cmp    %edi,%ebx
8010630f:	73 30                	jae    80106341 <loaduvm+0x87>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80106311:	89 da                	mov    %ebx,%edx
80106313:	03 55 0c             	add    0xc(%ebp),%edx
80106316:	b9 00 00 00 00       	mov    $0x0,%ecx
8010631b:	8b 45 08             	mov    0x8(%ebp),%eax
8010631e:	e8 64 fa ff ff       	call   80105d87 <walkpgdir>
80106323:	85 c0                	test   %eax,%eax
80106325:	74 b7                	je     801062de <loaduvm+0x24>
    pa = PTE_ADDR(*pte);
80106327:	8b 00                	mov    (%eax),%eax
80106329:	25 00 f0 ff ff       	and    $0xfffff000,%eax
    if(sz - i < PGSIZE)
8010632e:	89 fe                	mov    %edi,%esi
80106330:	29 de                	sub    %ebx,%esi
80106332:	81 fe ff 0f 00 00    	cmp    $0xfff,%esi
80106338:	76 b1                	jbe    801062eb <loaduvm+0x31>
      n = PGSIZE;
8010633a:	be 00 10 00 00       	mov    $0x1000,%esi
8010633f:	eb aa                	jmp    801062eb <loaduvm+0x31>
      return -1;
  }
  return 0;
80106341:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106346:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106349:	5b                   	pop    %ebx
8010634a:	5e                   	pop    %esi
8010634b:	5f                   	pop    %edi
8010634c:	5d                   	pop    %ebp
8010634d:	c3                   	ret    
      return -1;
8010634e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106353:	eb f1                	jmp    80106346 <loaduvm+0x8c>

80106355 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80106355:	55                   	push   %ebp
80106356:	89 e5                	mov    %esp,%ebp
80106358:	57                   	push   %edi
80106359:	56                   	push   %esi
8010635a:	53                   	push   %ebx
8010635b:	83 ec 0c             	sub    $0xc,%esp
8010635e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80106361:	39 7d 10             	cmp    %edi,0x10(%ebp)
80106364:	73 11                	jae    80106377 <deallocuvm+0x22>
    return oldsz;

  a = PGROUNDUP(newsz);
80106366:	8b 45 10             	mov    0x10(%ebp),%eax
80106369:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
8010636f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
  for(; a  < oldsz; a += PGSIZE){
80106375:	eb 19                	jmp    80106390 <deallocuvm+0x3b>
    return oldsz;
80106377:	89 f8                	mov    %edi,%eax
80106379:	eb 64                	jmp    801063df <deallocuvm+0x8a>
    pte = walkpgdir(pgdir, (char*)a, 0);
    if(!pte)
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
8010637b:	c1 eb 16             	shr    $0x16,%ebx
8010637e:	83 c3 01             	add    $0x1,%ebx
80106381:	c1 e3 16             	shl    $0x16,%ebx
80106384:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
  for(; a  < oldsz; a += PGSIZE){
8010638a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
80106390:	39 fb                	cmp    %edi,%ebx
80106392:	73 48                	jae    801063dc <deallocuvm+0x87>
    pte = walkpgdir(pgdir, (char*)a, 0);
80106394:	b9 00 00 00 00       	mov    $0x0,%ecx
80106399:	89 da                	mov    %ebx,%edx
8010639b:	8b 45 08             	mov    0x8(%ebp),%eax
8010639e:	e8 e4 f9 ff ff       	call   80105d87 <walkpgdir>
801063a3:	89 c6                	mov    %eax,%esi
    if(!pte)
801063a5:	85 c0                	test   %eax,%eax
801063a7:	74 d2                	je     8010637b <deallocuvm+0x26>
    else if((*pte & PTE_P) != 0){
801063a9:	8b 00                	mov    (%eax),%eax
801063ab:	a8 01                	test   $0x1,%al
801063ad:	74 db                	je     8010638a <deallocuvm+0x35>
      pa = PTE_ADDR(*pte);
      if(pa == 0)
801063af:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801063b4:	74 19                	je     801063cf <deallocuvm+0x7a>
        panic("kfree");
      char *v = P2V(pa);
801063b6:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
801063bb:	83 ec 0c             	sub    $0xc,%esp
801063be:	50                   	push   %eax
801063bf:	e8 c8 bb ff ff       	call   80101f8c <kfree>
      *pte = 0;
801063c4:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
801063ca:	83 c4 10             	add    $0x10,%esp
801063cd:	eb bb                	jmp    8010638a <deallocuvm+0x35>
        panic("kfree");
801063cf:	83 ec 0c             	sub    $0xc,%esp
801063d2:	68 c6 6a 10 80       	push   $0x80106ac6
801063d7:	e8 6c 9f ff ff       	call   80100348 <panic>
    }
  }
  return newsz;
801063dc:	8b 45 10             	mov    0x10(%ebp),%eax
}
801063df:	8d 65 f4             	lea    -0xc(%ebp),%esp
801063e2:	5b                   	pop    %ebx
801063e3:	5e                   	pop    %esi
801063e4:	5f                   	pop    %edi
801063e5:	5d                   	pop    %ebp
801063e6:	c3                   	ret    

801063e7 <allocuvm>:
{
801063e7:	55                   	push   %ebp
801063e8:	89 e5                	mov    %esp,%ebp
801063ea:	57                   	push   %edi
801063eb:	56                   	push   %esi
801063ec:	53                   	push   %ebx
801063ed:	83 ec 1c             	sub    $0x1c,%esp
801063f0:	8b 7d 10             	mov    0x10(%ebp),%edi
  if(newsz >= KERNBASE)
801063f3:	89 7d e4             	mov    %edi,-0x1c(%ebp)
801063f6:	85 ff                	test   %edi,%edi
801063f8:	0f 88 c1 00 00 00    	js     801064bf <allocuvm+0xd8>
  if(newsz < oldsz)
801063fe:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106401:	72 5c                	jb     8010645f <allocuvm+0x78>
  a = PGROUNDUP(oldsz);
80106403:	8b 45 0c             	mov    0xc(%ebp),%eax
80106406:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
8010640c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
  for(; a < newsz; a += PGSIZE){
80106412:	39 fe                	cmp    %edi,%esi
80106414:	0f 83 ac 00 00 00    	jae    801064c6 <allocuvm+0xdf>
    mem = kalloc();
8010641a:	e8 84 bc ff ff       	call   801020a3 <kalloc>
8010641f:	89 c3                	mov    %eax,%ebx
    if(mem == 0){
80106421:	85 c0                	test   %eax,%eax
80106423:	74 42                	je     80106467 <allocuvm+0x80>
    memset(mem, 0, PGSIZE);
80106425:	83 ec 04             	sub    $0x4,%esp
80106428:	68 00 10 00 00       	push   $0x1000
8010642d:	6a 00                	push   $0x0
8010642f:	50                   	push   %eax
80106430:	e8 f7 d8 ff ff       	call   80103d2c <memset>
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106435:	83 c4 08             	add    $0x8,%esp
80106438:	6a 06                	push   $0x6
8010643a:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106440:	50                   	push   %eax
80106441:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106446:	89 f2                	mov    %esi,%edx
80106448:	8b 45 08             	mov    0x8(%ebp),%eax
8010644b:	e8 a8 f9 ff ff       	call   80105df8 <mappages>
80106450:	83 c4 10             	add    $0x10,%esp
80106453:	85 c0                	test   %eax,%eax
80106455:	78 38                	js     8010648f <allocuvm+0xa8>
  for(; a < newsz; a += PGSIZE){
80106457:	81 c6 00 10 00 00    	add    $0x1000,%esi
8010645d:	eb b3                	jmp    80106412 <allocuvm+0x2b>
    return oldsz;
8010645f:	8b 45 0c             	mov    0xc(%ebp),%eax
80106462:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106465:	eb 5f                	jmp    801064c6 <allocuvm+0xdf>
      cprintf("allocuvm out of memory\n");
80106467:	83 ec 0c             	sub    $0xc,%esp
8010646a:	68 95 71 10 80       	push   $0x80107195
8010646f:	e8 93 a1 ff ff       	call   80100607 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80106474:	83 c4 0c             	add    $0xc,%esp
80106477:	ff 75 0c             	push   0xc(%ebp)
8010647a:	57                   	push   %edi
8010647b:	ff 75 08             	push   0x8(%ebp)
8010647e:	e8 d2 fe ff ff       	call   80106355 <deallocuvm>
      return 0;
80106483:	83 c4 10             	add    $0x10,%esp
80106486:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
8010648d:	eb 37                	jmp    801064c6 <allocuvm+0xdf>
      cprintf("allocuvm out of memory (2)\n");
8010648f:	83 ec 0c             	sub    $0xc,%esp
80106492:	68 ad 71 10 80       	push   $0x801071ad
80106497:	e8 6b a1 ff ff       	call   80100607 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010649c:	83 c4 0c             	add    $0xc,%esp
8010649f:	ff 75 0c             	push   0xc(%ebp)
801064a2:	57                   	push   %edi
801064a3:	ff 75 08             	push   0x8(%ebp)
801064a6:	e8 aa fe ff ff       	call   80106355 <deallocuvm>
      kfree(mem);
801064ab:	89 1c 24             	mov    %ebx,(%esp)
801064ae:	e8 d9 ba ff ff       	call   80101f8c <kfree>
      return 0;
801064b3:	83 c4 10             	add    $0x10,%esp
801064b6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801064bd:	eb 07                	jmp    801064c6 <allocuvm+0xdf>
    return 0;
801064bf:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
}
801064c6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801064c9:	8d 65 f4             	lea    -0xc(%ebp),%esp
801064cc:	5b                   	pop    %ebx
801064cd:	5e                   	pop    %esi
801064ce:	5f                   	pop    %edi
801064cf:	5d                   	pop    %ebp
801064d0:	c3                   	ret    

801064d1 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801064d1:	55                   	push   %ebp
801064d2:	89 e5                	mov    %esp,%ebp
801064d4:	56                   	push   %esi
801064d5:	53                   	push   %ebx
801064d6:	8b 75 08             	mov    0x8(%ebp),%esi
  uint i;

  if(pgdir == 0)
801064d9:	85 f6                	test   %esi,%esi
801064db:	74 1a                	je     801064f7 <freevm+0x26>
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
801064dd:	83 ec 04             	sub    $0x4,%esp
801064e0:	6a 00                	push   $0x0
801064e2:	68 00 00 00 80       	push   $0x80000000
801064e7:	56                   	push   %esi
801064e8:	e8 68 fe ff ff       	call   80106355 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
801064ed:	83 c4 10             	add    $0x10,%esp
801064f0:	bb 00 00 00 00       	mov    $0x0,%ebx
801064f5:	eb 10                	jmp    80106507 <freevm+0x36>
    panic("freevm: no pgdir");
801064f7:	83 ec 0c             	sub    $0xc,%esp
801064fa:	68 c9 71 10 80       	push   $0x801071c9
801064ff:	e8 44 9e ff ff       	call   80100348 <panic>
  for(i = 0; i < NPDENTRIES; i++){
80106504:	83 c3 01             	add    $0x1,%ebx
80106507:	81 fb ff 03 00 00    	cmp    $0x3ff,%ebx
8010650d:	77 1f                	ja     8010652e <freevm+0x5d>
    if(pgdir[i] & PTE_P){
8010650f:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
80106512:	a8 01                	test   $0x1,%al
80106514:	74 ee                	je     80106504 <freevm+0x33>
      char * v = P2V(PTE_ADDR(pgdir[i]));
80106516:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010651b:	05 00 00 00 80       	add    $0x80000000,%eax
      kfree(v);
80106520:	83 ec 0c             	sub    $0xc,%esp
80106523:	50                   	push   %eax
80106524:	e8 63 ba ff ff       	call   80101f8c <kfree>
80106529:	83 c4 10             	add    $0x10,%esp
8010652c:	eb d6                	jmp    80106504 <freevm+0x33>
    }
  }
  kfree((char*)pgdir);
8010652e:	83 ec 0c             	sub    $0xc,%esp
80106531:	56                   	push   %esi
80106532:	e8 55 ba ff ff       	call   80101f8c <kfree>
}
80106537:	83 c4 10             	add    $0x10,%esp
8010653a:	8d 65 f8             	lea    -0x8(%ebp),%esp
8010653d:	5b                   	pop    %ebx
8010653e:	5e                   	pop    %esi
8010653f:	5d                   	pop    %ebp
80106540:	c3                   	ret    

80106541 <setupkvm>:
{
80106541:	55                   	push   %ebp
80106542:	89 e5                	mov    %esp,%ebp
80106544:	56                   	push   %esi
80106545:	53                   	push   %ebx
  if((pgdir = (pde_t*)kalloc()) == 0)
80106546:	e8 58 bb ff ff       	call   801020a3 <kalloc>
8010654b:	89 c6                	mov    %eax,%esi
8010654d:	85 c0                	test   %eax,%eax
8010654f:	74 55                	je     801065a6 <setupkvm+0x65>
  memset(pgdir, 0, PGSIZE);
80106551:	83 ec 04             	sub    $0x4,%esp
80106554:	68 00 10 00 00       	push   $0x1000
80106559:	6a 00                	push   $0x0
8010655b:	50                   	push   %eax
8010655c:	e8 cb d7 ff ff       	call   80103d2c <memset>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106561:	83 c4 10             	add    $0x10,%esp
80106564:	bb 20 a4 10 80       	mov    $0x8010a420,%ebx
80106569:	81 fb 60 a4 10 80    	cmp    $0x8010a460,%ebx
8010656f:	73 35                	jae    801065a6 <setupkvm+0x65>
                (uint)k->phys_start, k->perm) < 0) {
80106571:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80106574:	8b 4b 08             	mov    0x8(%ebx),%ecx
80106577:	29 c1                	sub    %eax,%ecx
80106579:	83 ec 08             	sub    $0x8,%esp
8010657c:	ff 73 0c             	push   0xc(%ebx)
8010657f:	50                   	push   %eax
80106580:	8b 13                	mov    (%ebx),%edx
80106582:	89 f0                	mov    %esi,%eax
80106584:	e8 6f f8 ff ff       	call   80105df8 <mappages>
80106589:	83 c4 10             	add    $0x10,%esp
8010658c:	85 c0                	test   %eax,%eax
8010658e:	78 05                	js     80106595 <setupkvm+0x54>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80106590:	83 c3 10             	add    $0x10,%ebx
80106593:	eb d4                	jmp    80106569 <setupkvm+0x28>
      freevm(pgdir);
80106595:	83 ec 0c             	sub    $0xc,%esp
80106598:	56                   	push   %esi
80106599:	e8 33 ff ff ff       	call   801064d1 <freevm>
      return 0;
8010659e:	83 c4 10             	add    $0x10,%esp
801065a1:	be 00 00 00 00       	mov    $0x0,%esi
}
801065a6:	89 f0                	mov    %esi,%eax
801065a8:	8d 65 f8             	lea    -0x8(%ebp),%esp
801065ab:	5b                   	pop    %ebx
801065ac:	5e                   	pop    %esi
801065ad:	5d                   	pop    %ebp
801065ae:	c3                   	ret    

801065af <kvmalloc>:
{
801065af:	55                   	push   %ebp
801065b0:	89 e5                	mov    %esp,%ebp
801065b2:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
801065b5:	e8 87 ff ff ff       	call   80106541 <setupkvm>
801065ba:	a3 e4 46 11 80       	mov    %eax,0x801146e4
  switchkvm();
801065bf:	e8 1f fb ff ff       	call   801060e3 <switchkvm>
}
801065c4:	c9                   	leave  
801065c5:	c3                   	ret    

801065c6 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
801065c6:	55                   	push   %ebp
801065c7:	89 e5                	mov    %esp,%ebp
801065c9:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801065cc:	b9 00 00 00 00       	mov    $0x0,%ecx
801065d1:	8b 55 0c             	mov    0xc(%ebp),%edx
801065d4:	8b 45 08             	mov    0x8(%ebp),%eax
801065d7:	e8 ab f7 ff ff       	call   80105d87 <walkpgdir>
  if(pte == 0)
801065dc:	85 c0                	test   %eax,%eax
801065de:	74 05                	je     801065e5 <clearpteu+0x1f>
    panic("clearpteu");
  *pte &= ~PTE_U;
801065e0:	83 20 fb             	andl   $0xfffffffb,(%eax)
}
801065e3:	c9                   	leave  
801065e4:	c3                   	ret    
    panic("clearpteu");
801065e5:	83 ec 0c             	sub    $0xc,%esp
801065e8:	68 da 71 10 80       	push   $0x801071da
801065ed:	e8 56 9d ff ff       	call   80100348 <panic>

801065f2 <copyuvm>:
// Given a parent process's page table, create a copy
// of it for a child.
// don't take the garbage part of the space
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801065f2:	55                   	push   %ebp
801065f3:	89 e5                	mov    %esp,%ebp
801065f5:	57                   	push   %edi
801065f6:	56                   	push   %esi
801065f7:	53                   	push   %ebx
801065f8:	83 ec 1c             	sub    $0x1c,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
801065fb:	e8 41 ff ff ff       	call   80106541 <setupkvm>
80106600:	89 45 dc             	mov    %eax,-0x24(%ebp)
80106603:	85 c0                	test   %eax,%eax
80106605:	0f 84 c4 00 00 00    	je     801066cf <copyuvm+0xdd>
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010660b:	bf 00 00 00 00       	mov    $0x0,%edi
80106610:	3b 7d 0c             	cmp    0xc(%ebp),%edi
80106613:	0f 83 b6 00 00 00    	jae    801066cf <copyuvm+0xdd>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80106619:	89 7d e4             	mov    %edi,-0x1c(%ebp)
8010661c:	b9 00 00 00 00       	mov    $0x0,%ecx
80106621:	89 fa                	mov    %edi,%edx
80106623:	8b 45 08             	mov    0x8(%ebp),%eax
80106626:	e8 5c f7 ff ff       	call   80105d87 <walkpgdir>
8010662b:	85 c0                	test   %eax,%eax
8010662d:	74 65                	je     80106694 <copyuvm+0xa2>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
8010662f:	8b 00                	mov    (%eax),%eax
80106631:	a8 01                	test   $0x1,%al
80106633:	74 6c                	je     801066a1 <copyuvm+0xaf>
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
80106635:	89 c6                	mov    %eax,%esi
80106637:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    flags = PTE_FLAGS(*pte);
8010663d:	25 ff 0f 00 00       	and    $0xfff,%eax
80106642:	89 45 e0             	mov    %eax,-0x20(%ebp)
    if((mem = kalloc()) == 0)
80106645:	e8 59 ba ff ff       	call   801020a3 <kalloc>
8010664a:	89 c3                	mov    %eax,%ebx
8010664c:	85 c0                	test   %eax,%eax
8010664e:	74 6a                	je     801066ba <copyuvm+0xc8>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
80106650:	81 c6 00 00 00 80    	add    $0x80000000,%esi
80106656:	83 ec 04             	sub    $0x4,%esp
80106659:	68 00 10 00 00       	push   $0x1000
8010665e:	56                   	push   %esi
8010665f:	50                   	push   %eax
80106660:	e8 3f d7 ff ff       	call   80103da4 <memmove>
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0) {
80106665:	83 c4 08             	add    $0x8,%esp
80106668:	ff 75 e0             	push   -0x20(%ebp)
8010666b:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
80106671:	50                   	push   %eax
80106672:	b9 00 10 00 00       	mov    $0x1000,%ecx
80106677:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010667a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010667d:	e8 76 f7 ff ff       	call   80105df8 <mappages>
80106682:	83 c4 10             	add    $0x10,%esp
80106685:	85 c0                	test   %eax,%eax
80106687:	78 25                	js     801066ae <copyuvm+0xbc>
  for(i = 0; i < sz; i += PGSIZE){
80106689:	81 c7 00 10 00 00    	add    $0x1000,%edi
8010668f:	e9 7c ff ff ff       	jmp    80106610 <copyuvm+0x1e>
      panic("copyuvm: pte should exist");
80106694:	83 ec 0c             	sub    $0xc,%esp
80106697:	68 e4 71 10 80       	push   $0x801071e4
8010669c:	e8 a7 9c ff ff       	call   80100348 <panic>
      panic("copyuvm: page not present");
801066a1:	83 ec 0c             	sub    $0xc,%esp
801066a4:	68 fe 71 10 80       	push   $0x801071fe
801066a9:	e8 9a 9c ff ff       	call   80100348 <panic>
      kfree(mem);
801066ae:	83 ec 0c             	sub    $0xc,%esp
801066b1:	53                   	push   %ebx
801066b2:	e8 d5 b8 ff ff       	call   80101f8c <kfree>
      goto bad;
801066b7:	83 c4 10             	add    $0x10,%esp
    }
  }
  return d;

bad:
  freevm(d);
801066ba:	83 ec 0c             	sub    $0xc,%esp
801066bd:	ff 75 dc             	push   -0x24(%ebp)
801066c0:	e8 0c fe ff ff       	call   801064d1 <freevm>
  return 0;
801066c5:	83 c4 10             	add    $0x10,%esp
801066c8:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
}
801066cf:	8b 45 dc             	mov    -0x24(%ebp),%eax
801066d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
801066d5:	5b                   	pop    %ebx
801066d6:	5e                   	pop    %esi
801066d7:	5f                   	pop    %edi
801066d8:	5d                   	pop    %ebp
801066d9:	c3                   	ret    

801066da <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801066da:	55                   	push   %ebp
801066db:	89 e5                	mov    %esp,%ebp
801066dd:	83 ec 08             	sub    $0x8,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801066e0:	b9 00 00 00 00       	mov    $0x0,%ecx
801066e5:	8b 55 0c             	mov    0xc(%ebp),%edx
801066e8:	8b 45 08             	mov    0x8(%ebp),%eax
801066eb:	e8 97 f6 ff ff       	call   80105d87 <walkpgdir>
  if((*pte & PTE_P) == 0)
801066f0:	8b 00                	mov    (%eax),%eax
801066f2:	a8 01                	test   $0x1,%al
801066f4:	74 10                	je     80106706 <uva2ka+0x2c>
    return 0;
  if((*pte & PTE_U) == 0)
801066f6:	a8 04                	test   $0x4,%al
801066f8:	74 13                	je     8010670d <uva2ka+0x33>
    return 0;
  return (char*)P2V(PTE_ADDR(*pte));
801066fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801066ff:	05 00 00 00 80       	add    $0x80000000,%eax
}
80106704:	c9                   	leave  
80106705:	c3                   	ret    
    return 0;
80106706:	b8 00 00 00 00       	mov    $0x0,%eax
8010670b:	eb f7                	jmp    80106704 <uva2ka+0x2a>
    return 0;
8010670d:	b8 00 00 00 00       	mov    $0x0,%eax
80106712:	eb f0                	jmp    80106704 <uva2ka+0x2a>

80106714 <mprotect>:
int mprotect(void *addr,int len){
80106714:	55                   	push   %ebp
80106715:	89 e5                	mov    %esp,%ebp
80106717:	57                   	push   %edi
80106718:	56                   	push   %esi
80106719:	53                   	push   %ebx
8010671a:	83 ec 0c             	sub    $0xc,%esp
8010671d:	8b 75 08             	mov    0x8(%ebp),%esi
    if (len < 1){
80106720:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80106724:	7e 47                	jle    8010676d <mprotect+0x59>
    struct proc* curproc = myproc();
80106726:	e8 f0 ca ff ff       	call   8010321b <myproc>
8010672b:	89 c7                	mov    %eax,%edi
    for(int i = 0; i < len; i++){
8010672d:	bb 00 00 00 00       	mov    $0x0,%ebx
80106732:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
80106735:	7d 1e                	jge    80106755 <mprotect+0x41>
        char* map_address = uva2ka(curproc->pgdir, addr);
80106737:	83 ec 08             	sub    $0x8,%esp
8010673a:	56                   	push   %esi
8010673b:	ff 77 04             	push   0x4(%edi)
8010673e:	e8 97 ff ff ff       	call   801066da <uva2ka>
        if (map_address == 0){ 
80106743:	83 c4 10             	add    $0x10,%esp
80106746:	85 c0                	test   %eax,%eax
80106748:	74 2a                	je     80106774 <mprotect+0x60>
        addr+=PGSIZE;
8010674a:	81 c6 00 10 00 00    	add    $0x1000,%esi
    for(int i = 0; i < len; i++){
80106750:	83 c3 01             	add    $0x1,%ebx
80106753:	eb dd                	jmp    80106732 <mprotect+0x1e>
    lcr3(V2P(curproc->pgdir));
80106755:	8b 47 04             	mov    0x4(%edi),%eax
80106758:	05 00 00 00 80       	add    $0x80000000,%eax
8010675d:	0f 22 d8             	mov    %eax,%cr3
    return 0;
80106760:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106765:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106768:	5b                   	pop    %ebx
80106769:	5e                   	pop    %esi
8010676a:	5f                   	pop    %edi
8010676b:	5d                   	pop    %ebp
8010676c:	c3                   	ret    
        return -1;
8010676d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106772:	eb f1                	jmp    80106765 <mprotect+0x51>
        return -1;
80106774:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106779:	eb ea                	jmp    80106765 <mprotect+0x51>

8010677b <munprotect>:
int munprotect(void *addr,int len){
8010677b:	55                   	push   %ebp
8010677c:	89 e5                	mov    %esp,%ebp
8010677e:	57                   	push   %edi
8010677f:	56                   	push   %esi
80106780:	53                   	push   %ebx
80106781:	83 ec 0c             	sub    $0xc,%esp
80106784:	8b 75 08             	mov    0x8(%ebp),%esi
    if (len < 1){
80106787:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010678b:	7e 47                	jle    801067d4 <munprotect+0x59>
    struct proc* curproc = myproc();
8010678d:	e8 89 ca ff ff       	call   8010321b <myproc>
80106792:	89 c7                	mov    %eax,%edi
    for(int i = 0; i < len; i++){
80106794:	bb 00 00 00 00       	mov    $0x0,%ebx
80106799:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
8010679c:	7d 1e                	jge    801067bc <munprotect+0x41>
        char* map_address = uva2ka(curproc->pgdir, addr);
8010679e:	83 ec 08             	sub    $0x8,%esp
801067a1:	56                   	push   %esi
801067a2:	ff 77 04             	push   0x4(%edi)
801067a5:	e8 30 ff ff ff       	call   801066da <uva2ka>
        if (map_address == 0){ 
801067aa:	83 c4 10             	add    $0x10,%esp
801067ad:	85 c0                	test   %eax,%eax
801067af:	74 2a                	je     801067db <munprotect+0x60>
        addr+=PGSIZE;
801067b1:	81 c6 00 10 00 00    	add    $0x1000,%esi
    for(int i = 0; i < len; i++){
801067b7:	83 c3 01             	add    $0x1,%ebx
801067ba:	eb dd                	jmp    80106799 <munprotect+0x1e>
    lcr3(V2P(curproc->pgdir));
801067bc:	8b 47 04             	mov    0x4(%edi),%eax
801067bf:	05 00 00 00 80       	add    $0x80000000,%eax
801067c4:	0f 22 d8             	mov    %eax,%cr3
    return 0;
801067c7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801067cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
801067cf:	5b                   	pop    %ebx
801067d0:	5e                   	pop    %esi
801067d1:	5f                   	pop    %edi
801067d2:	5d                   	pop    %ebp
801067d3:	c3                   	ret    
        return -1;
801067d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067d9:	eb f1                	jmp    801067cc <munprotect+0x51>
        return -1;
801067db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067e0:	eb ea                	jmp    801067cc <munprotect+0x51>

801067e2 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801067e2:	55                   	push   %ebp
801067e3:	89 e5                	mov    %esp,%ebp
801067e5:	57                   	push   %edi
801067e6:	56                   	push   %esi
801067e7:	53                   	push   %ebx
801067e8:	83 ec 0c             	sub    $0xc,%esp
801067eb:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801067ee:	eb 25                	jmp    80106815 <copyout+0x33>
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (va - va0);
    if(n > len)
      n = len;
    memmove(pa0 + (va - va0), buf, n);
801067f0:	8b 55 0c             	mov    0xc(%ebp),%edx
801067f3:	29 f2                	sub    %esi,%edx
801067f5:	01 d0                	add    %edx,%eax
801067f7:	83 ec 04             	sub    $0x4,%esp
801067fa:	53                   	push   %ebx
801067fb:	ff 75 10             	push   0x10(%ebp)
801067fe:	50                   	push   %eax
801067ff:	e8 a0 d5 ff ff       	call   80103da4 <memmove>
    len -= n;
80106804:	29 df                	sub    %ebx,%edi
    buf += n;
80106806:	01 5d 10             	add    %ebx,0x10(%ebp)
    va = va0 + PGSIZE;
80106809:	8d 86 00 10 00 00    	lea    0x1000(%esi),%eax
8010680f:	89 45 0c             	mov    %eax,0xc(%ebp)
80106812:	83 c4 10             	add    $0x10,%esp
  while(len > 0){
80106815:	85 ff                	test   %edi,%edi
80106817:	74 2f                	je     80106848 <copyout+0x66>
    va0 = (uint)PGROUNDDOWN(va);
80106819:	8b 75 0c             	mov    0xc(%ebp),%esi
8010681c:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    pa0 = uva2ka(pgdir, (char*)va0);
80106822:	83 ec 08             	sub    $0x8,%esp
80106825:	56                   	push   %esi
80106826:	ff 75 08             	push   0x8(%ebp)
80106829:	e8 ac fe ff ff       	call   801066da <uva2ka>
    if(pa0 == 0)
8010682e:	83 c4 10             	add    $0x10,%esp
80106831:	85 c0                	test   %eax,%eax
80106833:	74 20                	je     80106855 <copyout+0x73>
    n = PGSIZE - (va - va0);
80106835:	89 f3                	mov    %esi,%ebx
80106837:	2b 5d 0c             	sub    0xc(%ebp),%ebx
8010683a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
    if(n > len)
80106840:	39 df                	cmp    %ebx,%edi
80106842:	73 ac                	jae    801067f0 <copyout+0xe>
      n = len;
80106844:	89 fb                	mov    %edi,%ebx
80106846:	eb a8                	jmp    801067f0 <copyout+0xe>
  }
  return 0;
80106848:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010684d:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106850:	5b                   	pop    %ebx
80106851:	5e                   	pop    %esi
80106852:	5f                   	pop    %edi
80106853:	5d                   	pop    %ebp
80106854:	c3                   	ret    
      return -1;
80106855:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010685a:	eb f1                	jmp    8010684d <copyout+0x6b>
