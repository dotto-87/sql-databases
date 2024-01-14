-- ZZEN9311 Assignment 2b
-- Schema for the mypics.net photo-sharing site
--
-- Written by David Otto (z5379919)
--
-- Conventions:
-- * all entity table names are plural
-- * most entities have an artificial primary key called "id"
-- * foreign keys are named after the relationship they represent

-- Domains (you may add more)

create domain URLValue as
	varchar(100) check (value like 'https://%');

create domain EmailValue as
	varchar(100) check (value like '%@%.%');

create domain GenderValue as
	varchar(6) check (value in ('male','female'));

create domain GroupModeValue as
	varchar(15) check (value in ('private','by-invitation','by-request'));

create domain NameValue as varchar(50);

create domain LongNameValue as varchar(100);

create domain VisibilityValue as
    varchar(14) check (value in ('private','friends','family','friends+family','public'));

create domain SafetyValue as
    varchar(10) check (value in ('safe','moderate','restricted'));

create domain CollectionValue as
    varchar(5) check (value in ('user','group'));

create domain RatingValue as
    integer check (value between 1 and 5);

-- Tables (you must add more)

create table People (
	PersonId        serial,
	FamilyName      LongNameValue,
	GivenNames      LongNameValue,
	DisplayedName   NameValue,
	EmailAddress    EmailValue not null,
	constraint HasName check
	    (FamilyName is not null or GivenNames is not null or DisplayedName is not null),
	primary key (PersonId)
);

create table Users (
	UserId          serial,
	Person          integer not null references People(PersonId),
	Website         URLValue,
	DateRegistered  timestamp not null,
	Gender          GenderValue,
	Birthday        date,
	"Password"      varchar not null,  --this field shall store encrypted strings as varchar
	Primary key (UserID)
);

create table Groups (
	GroupId     serial,
	"Mode"      GroupModeValue not null,
	Title       NameValue not null,
	OwnedBy     integer not null references Users(UserId),
	primary key (GroupId)
);

create table Friends (
    FListId     serial,
    Title       NameValue not null,
    OwnedBy     integer not null references Users(UserId),
    primary key (FListId)
);

create table Photos (
	PhotoId             serial,
	DateTaken           timestamp not null,
	Title               NameValue not null,
	DateUploaded        timestamp not null,
	Description         text not null,
	TechnicalDetails    text not null,
	SafetyLevel         SafetyValue not null,
	Visibility          VisibilityValue not null,
	PortraitYN          bool,
	Filesize            numeric check (Filesize > 0),
	User_Owns_Photo     integer not null references Users(UserId),
	constraint PortraitFileSize check
	    ((PortraitYN = true and Filesize <= 64) or (PortraitYN = false)),
	primary key (PhotoId)
);


create table Collections (
    CollectionId                serial,
    Title                       NameValue not null,
    Description                 text not null,
    CollectionType              CollectionValue,
    User_Owns_Collection        integer references Users(UserId),
    Group_Owns_Collection       integer references Groups(GroupId),
    Photo_Key                    integer references Photos(PhotoId),
        constraint UserOrGroup
            check ((CollectionType = 'user' and User_Owns_Collection is not null and Group_Owns_Collection is null) or
                   (CollectionType = 'group' and User_Owns_Collection is null and Group_Owns_Collection is not null)),
    primary key     (CollectionId)
);

create table Discussions (
    DiscussionId    serial,
    PhotoId         integer unique references Photos(PhotoId),
    GroupId         integer references Groups(GroupId),
    Title           LongNameValue,
        constraint PhotoOrGroup
            check ((PhotoId is not null and GroupId is null and Title is null) or
                   (PhotoId is null and GroupId is not null and Title is not null)),
    primary key (DiscussionId)
);

create table Comments (
    CommentId       serial,
    WhenPosted      TimeStamp not null,
    Content         text not null,
    Discussion      integer not null references Discussions(DiscussionId),
    Author          integer not null references Users(UserId),
    Reply           integer references Comments(CommentId),
    primary key (CommentId)
);

create table FriendsMembers (
    FriendList  integer references Friends(FListId),
    Person integer references People(PersonId),
    primary key (FriendList, Person)
);

create table GroupMembers (
    GroupId integer references Groups(GroupId),
    UserId integer references Users(UserId),
    primary key (GroupId, UserId)
);

create table User_Rates_Photo (
    UserId      integer references Users(UserId),
    PhotoId     integer references Photos(PhotoId),
    Rating      RatingValue not null,
    WhenRated   timestamp not null,
    primary key (UserId, PhotoId)
);

create table Tags (
    TagId       serial,
    TagName     NameValue unique,
    Freq        integer, --no check as other service will calculate it as positive integer
    primary key (TagId)
);

create table Photo_Has_Tag (
    PhotoId     integer references Photos(PhotoId),
    TagId       integer references Tags(TagId),
    WhenTagged  timestamp not null,
    primary key (PhotoId, TagId)
);

create table Collection_Has_Photos (
    CollectionId    integer references Collections(CollectionId),
    PhotoId         integer references Photos(PhotoId),
    RankOrder       integer check (RankOrder > 0),
    primary key  (CollectionId, PhotoId, RankOrder),
    unique (CollectionId, RankOrder)
);

create table Portraits (
    UserId      integer unique references Users(UserId),
    PhotoId     integer unique references Photos(PhotoId),
    primary key (UserId, PhotoId)
);