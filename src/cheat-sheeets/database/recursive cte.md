WITH CTE AS (
	SELECT Id, UserId, IdeaId, Body, [DateTime], Username, FirstName, LastName, ParentId, [1] as Likes, [0] Dislikes,
	count(*) over(ORDER BY IdeaId) TotalCount
	FROM
	(SELECT c.Id, c.UserId, c.IdeaId, c.Body, c.[DateTime], u.Username, u.FirstName, u.LastName, c.ParentId, vc.[like] 
	FROM Comment as c JOIN [User] as u ON c.UserId = u.Id
	LEFT JOIN VoteComment as vc ON vc.CommentId = c.Id
	WHERE c.IdeaId = 7 and c.ParentId is NULL) q
	PIVOT
	(count(q.[like])
	FOR q.[like] in ([1] , [0]) ) as piv
	UNION ALL
	SELECT c1.Id, count(*) as RepliesCount
	from comment c1 JOIN comment c2 ON c1.Id = c2.ParentId
	GROUP BY c1.Id
) 
SELECT * FROM CTE;