/*
    NSInputManagerPriv.m

    Copyright (C) 2004 Free Software Foundation, Inc.

    Author: Kazunobu Kuriyama <kazunobu.kuriyama@nifty.com>
    Date:   March, 2004

    This file is part of the GNUstep GUI Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; see the file COPYING.LIB.
    If not, write to the Free Software Foundation,
    59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>

#if !defined USE_INPUT_MANAGER_UTILITIES
#define USE_INPUT_MANAGER_UTILITIES
#endif
#include "NSInputManagerPriv.h"


#define NumberOf(array) (sizeof(array)/sizeof(array[0]))


typedef struct _IMRecord {
    NSString	    *key;
    unsigned int    value;
} IMRecord;


static IMRecord functionKeyTable[] = {
    { @"UpArrow",	    NSUpArrowFunctionKey },
    { @"DownArrow",	    NSDownArrowFunctionKey },
    { @"LeftArrow",	    NSLeftArrowFunctionKey },
    { @"RightArrow",	    NSRightArrowFunctionKey },
    { @"F1",		    NSF1FunctionKey },
    { @"F2",		    NSF2FunctionKey },
    { @"F3",		    NSF3FunctionKey },
    { @"F4",		    NSF4FunctionKey },
    { @"F5",		    NSF5FunctionKey },
    { @"F6",		    NSF6FunctionKey },
    { @"F7",		    NSF7FunctionKey },
    { @"F8",		    NSF8FunctionKey },
    { @"F9",		    NSF9FunctionKey },
    { @"F10",		    NSF10FunctionKey },
    { @"F11",		    NSF11FunctionKey },
    { @"F12",		    NSF12FunctionKey },
    { @"F13",		    NSF13FunctionKey },
    { @"F14",		    NSF14FunctionKey },
    { @"F15",		    NSF15FunctionKey },
    { @"F16",		    NSF16FunctionKey },
    { @"F17",		    NSF17FunctionKey },
    { @"F18",		    NSF18FunctionKey },
    { @"F19",		    NSF19FunctionKey },
    { @"F20",		    NSF20FunctionKey },
    { @"F21",		    NSF21FunctionKey },
    { @"F22",		    NSF22FunctionKey },
    { @"F23",		    NSF23FunctionKey },
    { @"F24",		    NSF24FunctionKey },
    { @"F25",		    NSF25FunctionKey },
    { @"F26",		    NSF26FunctionKey },
    { @"F27",		    NSF27FunctionKey },
    { @"F28",		    NSF28FunctionKey },
    { @"F29",		    NSF29FunctionKey },
    { @"F30",		    NSF30FunctionKey },
    { @"F31",		    NSF31FunctionKey },
    { @"F32",		    NSF32FunctionKey },
    { @"F33",		    NSF33FunctionKey },
    { @"F34",		    NSF34FunctionKey },
    { @"F35",		    NSF35FunctionKey },
    { @"Insert",	    NSInsertFunctionKey },
    { @"Delete",	    NSDeleteFunctionKey },
    { @"Home",		    NSHomeFunctionKey },
    { @"Begin",		    NSBeginFunctionKey },
    { @"End",		    NSEndFunctionKey },
    { @"PageUp",	    NSPageUpFunctionKey },
    { @"PageDown",	    NSPageDownFunctionKey },
    { @"PrintScreen",	    NSPrintScreenFunctionKey },
    { @"ScrollLock",	    NSScrollLockFunctionKey },
    { @"Pause",		    NSPauseFunctionKey },
    { @"SysReq",	    NSSysReqFunctionKey },
    { @"Break",		    NSBreakFunctionKey },
    { @"Reset",		    NSResetFunctionKey },
    { @"Stop",		    NSStopFunctionKey },
    { @"Menu",		    NSMenuFunctionKey },
    { @"User",		    NSUserFunctionKey },
    { @"System",	    NSSystemFunctionKey },
    { @"Print",		    NSPrintFunctionKey },
    { @"ClearLine",	    NSClearLineFunctionKey },
    { @"ClearDisplay",	    NSClearDisplayFunctionKey },
    { @"InsertLine",	    NSInsertLineFunctionKey },
    { @"DeleteLine",	    NSDeleteLineFunctionKey },
    { @"InsertChar",	    NSInsertCharFunctionKey },
    { @"DeleteChar",	    NSDeleteCharFunctionKey },
    { @"Prev",		    NSPrevFunctionKey },
    { @"Next",		    NSNextFunctionKey },
    { @"Select",	    NSSelectFunctionKey },
    { @"Execute",	    NSExecuteFunctionKey },
    { @"Undo",		    NSUndoFunctionKey },
    { @"Redo",		    NSRedoFunctionKey },
    { @"Find",		    NSFindFunctionKey },
    { @"Help",		    NSHelpFunctionKey },
    { @"Mode",		    NSModeSwitchFunctionKey },
};


static IMRecord maskTable[] = {
    { @"AlphaShiftKey",	    NSAlphaShiftKeyMask },
    { @"ShiftKey",	    NSShiftKeyMask },
    { @"ControlKey",	    NSControlKeyMask },
    { @"AlternateKey",	    NSAlternateKeyMask },
    { @"CommandKey",	    NSCommandKeyMask },
    { @"NumericPadKey",	    NSNumericPadKeyMask },
    { @"HelpKey",	    NSHelpKeyMask },
    { @"FunctionKey",	    NSFunctionKeyMask },
};


@interface NSInputManager (Debug)
- (NSString *)modifierFlagsToString: (unsigned int)flags;
- (NSString *)nonprintableToPrintable:(NSString *)str;
@end /* @interface NSInputManager (Debug) */


@implementation NSInputManager (KeyEventHandling)

- (void)interpretSingleKeyEvent: (NSEvent *)event
{
  NSString	*characters = [event characters];
  NSString	*noModifiers = [event charactersIgnoringModifiers];
  unsigned int	modifierFlags = [event modifierFlags];

  /* TODO: Under experiment */
  if ([self wantsToInterpretAllKeystrokes])
    {
      [self insertText: characters];
    }

  /* For debugging */
  NSLog(@"%@ -> %@ (%@)",
	characters,
	[self nonprintableToPrintable: noModifiers],
	[self modifierFlagsToString: modifierFlags]);

  if ([[event characters] characterAtIndex: 0] == 010) /* Backspace */
    {
      /* Interestingly, Ctrl-h comes here.  Who does this conversion? */
      [self doCommandBySelector: @selector(deleteBackward:)];
    }
  else if ([characters characterAtIndex: 0] == 015) /* CR */
    {
      [self doCommandBySelector: @selector(insertNewline:)];
    }
  else if ([characters characterAtIndex: 0] == 011) /* TAB */
    {
      [self doCommandBySelector: @selector(insertTab:)];
    }
  else if (modifierFlags == 0 ||
	   (modifierFlags & NSShiftKeyMask) == NSShiftKeyMask ||
	   (modifierFlags & NSAlphaShiftKeyMask) == NSAlphaShiftKeyMask)
    {
      [self insertText: [event characters]];
    }
}


- (void)interpretKeyEvents: (NSArray *)eventArray
{
  id		obj;
  NSEnumerator	*objEnum    = [eventArray objectEnumerator];

  while ((obj = [objEnum nextObject]) != nil)
    {
      [self interpretSingleKeyEvent: obj];
    }
}

@end /* @implementation NSInputManager (KeyEventHandling) */


@implementation IMCharacter

- (id)init
{
  return [self initWithCharacter: 0
		       modifiers: 0];
}


- (id)initWithCharacter: (unichar)c
	      modifiers: (unsigned int)flags
{
  if ((self = [super init]) != nil)
    {
      [self setCharacter: c];
      [self setModifiers: flags];
    }
  return self;
}


- (id)characterWithCharacter: (unichar)c
		   modifiers: (unsigned int)flags
{
  return [[[self class] initWithCharacter: c modifiers: flags] autorelease];
}


- (void)setCharacter: (unichar)c
{
  character = c;
}


- (unichar)character
{
  return character;
}


- (void)setModifiers: (unsigned int)flags
{
  modifiers = flags;
}


- (unsigned int)modifiers
{
  return modifiers;
}


- (id)copyWithZone: (NSZone *)zone
{
  IMCharacter *c = [[[self class] allocWithZone: zone]
				initWithCharacter: [self character]
					modifiers: [self modifiers]];
  return c;
}


- (BOOL)equalTo: (id)anObject
{
  if ([anObject isMemberOf: [IMCharacter class]])
    {
      return ([anObject character] == [self character]) &&
	     ([anObject modifiers] == [self modifiers]);
    }
  return NO;
}


- (NSComparisonResult)compare: (id)another
{
  unsigned long val1 = ([self modifiers] << (sizeof(unichar) * 8))
			& [self character];
  unsigned long val2 = ([another modifiers] << (sizeof(unichar) * 8))
			& [another character];
  if (val2 > val1)
    {
      return NSOrderedDescending;
    }
  else if (val2 < val1)
    {
      return NSOrderedAscending;
    }
  else
    {
      return NSOrderedSame;
    }
}


- (NSString *)description
{
  /* TODO: Under construction */
  return nil;
}

@end /* @implementation IMCharacter */


@implementation IMKeyBindingTable

- (id)initWithKeyBindingDictionary: (NSDictionary *)bindings
{
  if ((self = [super init]) != nil)
    {
      /* TODO: Under construction */
    }
  return nil;
}


- (IMQueryResult)getSelectorForCharacter: (IMCharacter *)c
				selector: (SEL *)sel
{
  /* TODO: Under construction */
  return IMNotFound;
}

- (void)dealloc
{
  [bindings release];
  /* Don't release 'branch' because it is a pointer to either 'bindings'
     or a dictionary inside 'branch'. */
  [super dealloc];
}

@end /* @implementation IMKeyBindingTable */


@implementation NSInputManager (Debug)

- (NSString *)modifierFlagsToString: (unsigned int)flags
{
  NSString *str = [NSString stringWithString: @""];
  unsigned i;

  for (i = 0; i < NumberOf(maskTable); i++)
    {
      if (flags & maskTable[i].value)
	{
	  str = [str stringByAppendingString: maskTable[i].key];
	  str = [str stringByAppendingString: @" "];
	}
    }
  return str;
}


- (NSString *)nonprintableToPrintable:(NSString *)chars
{
  NSString	*str = [NSString stringWithString: @""];
  unsigned int	i, j;
  unichar	c;

  for (i = 0; i < [chars length]; i++)
    {
      c = [chars characterAtIndex: i];

      for (j = 0; j < NumberOf(functionKeyTable); j++)
	{
	  if (functionKeyTable[j].value == c)
	    {
	      str = [str stringByAppendingString: functionKeyTable[j].key];
	      str = [str stringByAppendingString: @" "];
	      break;
	    }
	}
      if (j == NumberOf(functionKeyTable))
	{
	  if ((c > 040 && c < 0177) ||	/* Printable ASCII */
	      c >= 0200)		/* non-ASCII */
	    {
	      str = [str stringByAppendingString:
			[NSString stringWithCharacters: &c length: 1]];
	    }
	  else
	    {
	      /* Non-printable ASCII */
	      switch (c)
		{
		case 000:
		  str = [str stringByAppendingString: @"NUL"];	/* \0 */
		  break;
		case 001:
		  str = [str stringByAppendingString: @"SOH"];
		  break;
		case 002:
		  str = [str stringByAppendingString: @"STX"];
		  break;
		case 003:
		  str = [str stringByAppendingString: @"ETX"];
		  break;
		case 004:
		  str = [str stringByAppendingString: @"EOT"];
		  break;
		case 005:
		  str = [str stringByAppendingString: @"ENQ"];
		  break;
		case 006:
		  str = [str stringByAppendingString: @"ACK"];
		  break;
		case 007:
		  str = [str stringByAppendingString: @"BEL"];	/* \a */
		  break;
		case 010:
		  str = [str stringByAppendingString: @"BS"];	/* \b */
		  break;
		case 011:
		  str = [str stringByAppendingString: @"TAB"];	/* \t */
		  break;
		case 012:
		  str = [str stringByAppendingString: @"LF"];	/* \n */
		  break;
		case 013:
		  str = [str stringByAppendingString: @"VT"];	/* \v */
		  break;
		case 014:
		  str = [str stringByAppendingString: @"FF"];	/* \f */
		  break;
		case 015:
		  str = [str stringByAppendingString: @"CR"];	/* \r */
		  break;
		case 016:
		  str = [str stringByAppendingString: @"SO"];
		  break;
		case 017:
		  str = [str stringByAppendingString: @"SI"];
		  break;
		case 020:
		  str = [str stringByAppendingString: @"DLE"];
		  break;
		case 021:
		  str = [str stringByAppendingString: @"DC1"];
		  break;
		case 022:
		  str = [str stringByAppendingString: @"DC2"];
		  break;
		case 023:
		  str = [str stringByAppendingString: @"DC3"];
		  break;
		case 024:
		  str = [str stringByAppendingString: @"DC4"];
		  break;
		case 025:
		  str = [str stringByAppendingString: @"NAK"];
		  break;
		case 026:
		  str = [str stringByAppendingString: @"SYN"];
		  break;
		case 027:
		  str = [str stringByAppendingString: @"ETB"];
		  break;
		case 030:
		  str = [str stringByAppendingString: @"CAN"];
		  break;
		case 031:
		  str = [str stringByAppendingString: @"EM"];
		  break;
		case 032:
		  str = [str stringByAppendingString: @"SUB"];
		  break;
		case 033:
		  str = [str stringByAppendingString: @"ESC"];	/* Esc */
		  break;
		case 034:
		  str = [str stringByAppendingString: @"FS"];
		  break;
		case 035:
		  str = [str stringByAppendingString: @"GS"];
		  break;
		case 036:
		  str = [str stringByAppendingString: @"RS"];
		  break;
		case 037:
		  str = [str stringByAppendingString: @"US"];
		case 040:
		  str = [str stringByAppendingString: @"SPACE"];
		  break;
		case 0177:
		  str = [str stringByAppendingString: @"DEL"];
		  break;
		default:
		  break;
		}
	    }
	}
    }
  return str;
}

@end /* NSInputManager (Debug) */
