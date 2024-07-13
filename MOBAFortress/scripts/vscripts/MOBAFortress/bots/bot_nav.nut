currentPath <- [];
pathLen <- 0;
pathNum <- 0;
pathDistance <- 9999;
pathFailed <- true;
needsNewPath <- true;
isCloseToTarget <- false;

function MoveByCurrentPath(speed = 321)
{
    if (!isCloseToTarget && (pathLen == 0 || pathNum > pathLen))
        return;

    local targetPos = isCloseToTarget && playerTarget ? targetOrigin : currentPath[pathNum];
    local dist = (targetPos - self.GetOrigin()).Length2D();

	if (dist < 125.0 && ++pathNum >= pathLen)
	{
        pathLen = 0;
		needsNewPath = true;
	}
    if (!isCloseToTarget || dist > 125)
    {
        self.GetLocomotionInterface().SetDesiredSpeed(speed);
        self.GetLocomotionInterface().Approach(targetPos, 1.0)
    }

    local forward = self.GetForwardVector();
    local targetVector = targetPos - self.GetOrigin();
    targetVector.Norm();
    local deltaVector = targetVector - forward;
    deltaVector.z = 0;
    local newForward = forward + deltaVector * 0.1;
    self.SetForwardVector(newForward);
}

function SetStraightPath(endPos)
{
    endPos += Vector(0, 0, 12);
    local myPos = self.GetOrigin() + Vector(0, 0, 12);

    currentPath = [endPos];
    pathNum = 0;
    pathLen = 1;
    needsNewPath = false;
}

function SetNewPath(endPos)
{
    local myPos = self.GetOrigin() + Vector(0, 0, 12);

    if (playerTarget)
    {
        local targetPos = targetOrigin + Vector(0, 0, 12);
        local deltaVector = myPos - targetPos;
        local distance = deltaVector.Norm();
        isCloseToTarget = distance < 250 && TraceLine(myPos, targetPos, krampus) > 0.95;
        if (isCloseToTarget)
            return;
    }
    else
        isCloseToTarget = false;
    pathFailed = false;
    endPos += Vector(0, 0, 12);

    local myArea = NavMesh.GetNavArea(myPos, 512);
    local endArea = NavMesh.GetNavArea(endPos, 512);
    if (!myArea)
        myArea = NavMesh.GetNearestNavArea(myPos, 512, false, true);
    if (!endArea)
        endArea = NavMesh.GetNearestNavArea(endPos, 512, false, true);

    local result = {};
    NavMesh.GetNavAreasFromBuildPath(myArea, endArea, endPos, 0, 5, false, result);

    local path = [endPos];
    local len = result.len();
    local newDistance = -10;
    local lastPos = endPos;
    for (local i = 1; i < len; i++)
    {
        local resultPos = result["area"+i].GetCenter();
        local deltaVector = lastPos - resultPos;
        if (deltaVector.z < -80)
        {
            currentPath = [endPos];
            pathNum = 0;
            pathLen = 0;
            needsNewPath = true;
            pathDistance = -10;
            pathFailed = true;
            return;
        }
        newDistance += deltaVector.Length2D();
        lastPos = resultPos;
        path.push(resultPos);
    }
    path.reverse();

    currentPath = path;
    pathNum = 0;
    pathLen = len;
    needsNewPath = len == 0;
    pathDistance = newDistance;

    if (len == 0)
    {
        pathFailed = true;
        pathDistance = 9999;
    }
}